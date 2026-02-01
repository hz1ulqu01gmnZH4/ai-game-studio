#!/usr/bin/env python3
"""
Queue Watcher — event-driven Manager notifier using Linux inotify.

TEMPORARILY SUSPENDED: Workers now notify the Manager directly via
tmux send-keys (step 7 in specialist Task Protocol). This watcher is
kept as a fallback in case worker notifications prove unreliable.
To re-enable, add back to scripts/launch.sh (see git history).

Watches queue/done/ and queue/pending/ for file events and pokes the
Manager's tmux pane so it processes the change immediately.

Zero dependencies — uses raw inotify syscalls via ctypes.

Usage:
    python3 scripts/queue-watcher.py [--pane-targets config/pane_targets.yaml]

Runs as a background daemon.
Kill with: kill $(cat /tmp/queue-watcher.pid)
"""

import ctypes
import ctypes.util
import struct
import os
import sys
import subprocess
import time
import signal
import argparse
from pathlib import Path

# ── inotify constants ──────────────────────────────────────────────────
IN_CREATE = 0x00000100
IN_MOVED_TO = 0x00000080
IN_CLOSE_WRITE = 0x00000008
IN_DELETE = 0x00000200
IN_MOVED_FROM = 0x00000040

WATCH_MASK = IN_CREATE | IN_MOVED_TO | IN_CLOSE_WRITE | IN_DELETE | IN_MOVED_FROM

# ── inotify syscalls via libc ─────────────────────────────────────────
libc = ctypes.CDLL(ctypes.util.find_library("c"), use_errno=True)


def inotify_init():
    fd = libc.inotify_init()
    if fd < 0:
        errno = ctypes.get_errno()
        raise OSError(errno, f"inotify_init failed: {os.strerror(errno)}")
    return fd


def inotify_add_watch(fd, path, mask):
    wd = libc.inotify_add_watch(fd, path.encode(), mask)
    if wd < 0:
        errno = ctypes.get_errno()
        raise OSError(errno, f"inotify_add_watch failed for {path}: {os.strerror(errno)}")
    return wd


def read_events(fd):
    """Read and yield inotify events. Blocks until events available."""
    buf = os.read(fd, 4096)
    offset = 0
    while offset < len(buf):
        wd, mask, cookie, name_len = struct.unpack_from("iIII", buf, offset)
        offset += struct.calcsize("iIII")
        name = buf[offset : offset + name_len].rstrip(b"\x00").decode(errors="replace")
        offset += name_len
        yield wd, mask, name


# ── Manager pane resolution ───────────────────────────────────────────

def get_manager_pane(pane_targets_path):
    """Read manager pane ID from pane_targets.yaml."""
    with open(pane_targets_path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("manager:"):
                # manager: "%60"
                return line.split('"')[1]
    raise RuntimeError(f"No manager pane found in {pane_targets_path}")


def poke_manager(pane_id, message):
    """Send a message to the Manager's tmux pane."""
    try:
        subprocess.run(
            ["tmux", "send-keys", "-t", pane_id, message],
            check=True,
            capture_output=True,
            timeout=5,
        )
        subprocess.run(
            ["tmux", "send-keys", "-t", pane_id, "Enter"],
            check=True,
            capture_output=True,
            timeout=5,
        )
    except subprocess.CalledProcessError as e:
        print(f"[queue-watcher] WARN: failed to poke manager: {e.stderr.decode()}", file=sys.stderr)
    except subprocess.TimeoutExpired:
        print("[queue-watcher] WARN: tmux send-keys timed out", file=sys.stderr)


# ── Debounce ──────────────────────────────────────────────────────────

class Debouncer:
    """
    Coalesce rapid file events into a single Manager poke.
    Waits `delay` seconds after the last event before firing.
    """

    def __init__(self, delay=3.0):
        self.delay = delay
        self.last_event_time = 0
        self.pending_events = []

    def add(self, event_desc):
        self.last_event_time = time.monotonic()
        self.pending_events.append(event_desc)

    def ready(self):
        if not self.pending_events:
            return False
        return (time.monotonic() - self.last_event_time) >= self.delay

    def flush(self):
        events = self.pending_events[:]
        self.pending_events.clear()
        return events


# ── Main loop ─────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Queue watcher for AI Game Studio")
    parser.add_argument(
        "--pane-targets",
        default="config/pane_targets.yaml",
        help="Path to pane_targets.yaml",
    )
    parser.add_argument(
        "--studio-dir",
        default=None,
        help="Studio root directory (default: script parent's parent)",
    )
    parser.add_argument(
        "--debounce",
        type=float,
        default=3.0,
        help="Seconds to wait before notifying after last event (default: 3)",
    )
    args = parser.parse_args()

    # Resolve studio dir
    if args.studio_dir:
        studio_dir = Path(args.studio_dir)
    else:
        studio_dir = Path(__file__).resolve().parent.parent

    pane_targets = studio_dir / args.pane_targets

    # Directories to watch
    watch_dirs = {
        "done": studio_dir / "queue" / "done",
        "pending": studio_dir / "queue" / "pending",
        "in-progress": studio_dir / "queue" / "in-progress",
    }

    # Ensure dirs exist
    for d in watch_dirs.values():
        d.mkdir(parents=True, exist_ok=True)

    # Resolve manager pane
    manager_pane = get_manager_pane(str(pane_targets))
    print(f"[queue-watcher] Manager pane: {manager_pane}", file=sys.stderr)

    # Write PID file
    pid_file = Path("/tmp/queue-watcher.pid")
    pid_file.write_text(str(os.getpid()))

    # Clean shutdown
    def handle_signal(signum, frame):
        print(f"[queue-watcher] Caught signal {signum}, exiting.", file=sys.stderr)
        pid_file.unlink(missing_ok=True)
        sys.exit(0)

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    # Set up inotify
    fd = inotify_init()
    wd_to_name = {}
    for name, path in watch_dirs.items():
        wd = inotify_add_watch(fd, str(path), WATCH_MASK)
        wd_to_name[wd] = name
        print(f"[queue-watcher] Watching {path} (wd={wd})", file=sys.stderr)

    print("[queue-watcher] Running. Events will poke Manager automatically.", file=sys.stderr)

    debouncer = Debouncer(delay=args.debounce)

    # Use select for non-blocking read with timeout
    import select

    while True:
        # Wait for events with 1s timeout (to check debouncer)
        readable, _, _ = select.select([fd], [], [], 1.0)

        if readable:
            for wd, mask, name in read_events(fd):
                if not name or not name.endswith(".md"):
                    continue
                dir_name = wd_to_name.get(wd, "?")

                desc_parts = []
                if mask & IN_CREATE:
                    desc_parts.append("created")
                if mask & IN_MOVED_TO:
                    desc_parts.append("moved_to")
                if mask & IN_CLOSE_WRITE:
                    desc_parts.append("written")
                if mask & IN_DELETE:
                    desc_parts.append("deleted")
                if mask & IN_MOVED_FROM:
                    desc_parts.append("moved_from")

                action = "+".join(desc_parts) if desc_parts else f"mask={mask}"
                event = f"{name} {action} in queue/{dir_name}/"
                print(f"[queue-watcher] Event: {event}", file=sys.stderr)
                debouncer.add(event)

        # Check if debouncer is ready to fire
        if debouncer.ready():
            events = debouncer.flush()
            summary = "; ".join(events[-5:])  # Last 5 events max in message
            if len(events) > 5:
                summary = f"{len(events)} queue changes including: {summary}"

            message = f"QUEUE EVENT: {summary}. Check queue/done/ queue/pending/ queue/in-progress/ and take action: update dashboard, dispatch unblocked tasks, clean up stale files."
            print(f"[queue-watcher] Poking manager: {message}", file=sys.stderr)
            poke_manager(manager_pane, message)


if __name__ == "__main__":
    main()
