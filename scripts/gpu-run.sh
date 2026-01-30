#!/bin/bash
# GPU VRAM Reservation Manager
# Ensures GPU jobs don't exceed available VRAM. Multiple jobs can run concurrently if VRAM allows.
#
# Usage: scripts/gpu-run.sh --vram <MB> --caller <role> [--timeout <sec>] -- <command...>
#
# Examples:
#   scripts/gpu-run.sh --vram 6500 --caller asset_generator -- python tts_job.py
#   scripts/gpu-run.sh --vram 8500 --caller asset_generator --timeout 300 -- python sd_generate.py
#
# Common VRAM values:
#   Qwen3-TTS:        6500
#   Stable Diffusion:  8500
#   TRELLIS.2:         8500
#   Qwen-Image:        6500

set -uo pipefail

STUDIO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOCK_FILE="$STUDIO_DIR/queue/gpu/lock"
RESERVATIONS_DIR="$STUDIO_DIR/queue/gpu/reservations"
HISTORY_DIR="$STUDIO_DIR/queue/gpu/history"

# --- Parse arguments ---
VRAM=""
CALLER="unknown"
TIMEOUT=600
CMD=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --vram)   VRAM="$2"; shift 2 ;;
        --caller) CALLER="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --)       shift; CMD=("$@"); break ;;
        *)        echo "ERROR: Unknown argument '$1'" >&2
                  echo "Usage: gpu-run.sh --vram <MB> --caller <role> [--timeout <sec>] -- <command...>" >&2
                  exit 1 ;;
    esac
done

if [[ -z "$VRAM" ]]; then
    echo "ERROR: --vram is required" >&2
    exit 1
fi

if [[ ${#CMD[@]} -eq 0 ]]; then
    echo "ERROR: No command specified after --" >&2
    exit 1
fi

JOB_ID="$(date +%s)-$$"
RESERVATION_FILE="$RESERVATIONS_DIR/${JOB_ID}.json"

# --- Cleanup on exit (success, failure, kill, crash) ---
cleanup() {
    local exit_code=$?
    rm -f "$RESERVATION_FILE"

    # Write history
    local ended
    ended="$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)"
    local status="completed"
    [[ $exit_code -ne 0 ]] && status="failed"

    printf '{"job_id":"%s","vram_mb":%s,"caller":"%s","status":"%s","exit_code":%s,"ended":"%s","command":"%s"}\n' \
        "$JOB_ID" "$VRAM" "$CALLER" "$status" "$exit_code" "$ended" "${CMD[*]}" \
        > "$HISTORY_DIR/${JOB_ID}.json"
}
trap cleanup EXIT

# --- Sum active reservations (cleans stale ones) ---
sum_reserved() {
    local total=0
    local f
    for f in "$RESERVATIONS_DIR"/*.json; do
        [[ -f "$f" ]] || continue
        # Check if the owning process is still alive
        local pid
        pid=$(grep -o '"pid":[0-9]*' "$f" 2>/dev/null | grep -o '[0-9]*' || true)
        if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
            # Stale reservation — process died without cleanup (SIGKILL)
            rm -f "$f"
            continue
        fi
        local v
        v=$(grep -o '"vram_mb":[0-9]*' "$f" 2>/dev/null | grep -o '[0-9]*' || echo "0")
        total=$((total + v))
    done
    echo "$total"
}

# --- Get free VRAM from nvidia-smi ---
get_free_vram() {
    nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' '
}

# --- Write reservation file ---
write_reservation() {
    printf '{"job_id":"%s","vram_mb":%s,"caller":"%s","pid":%s,"started":"%s","command":"%s"}\n' \
        "$JOB_ID" "$VRAM" "$CALLER" "$$" "$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)" "${CMD[*]}" \
        > "$RESERVATION_FILE"
}

# --- Try to reserve VRAM (called while holding flock) ---
# Returns 0 if reserved, 1 if not enough VRAM
try_reserve() {
    local free_vram
    free_vram=$(get_free_vram)

    if [[ -z "$free_vram" ]]; then
        echo "WARNING: nvidia-smi unavailable. Proceeding without VRAM check." >&2
        write_reservation
        return 0
    fi

    local total_reserved
    total_reserved=$(sum_reserved)
    local available=$((free_vram - total_reserved))

    if [[ $available -ge $VRAM ]]; then
        write_reservation
        return 0
    else
        return 1
    fi
}

# --- Reservation loop ---
MAX_RETRIES=60
RETRY_DELAY=10
RESERVED=false

for i in $(seq 1 $MAX_RETRIES); do
    # Acquire short flock for atomic check+reserve, then release
    {
        flock -x 9
        if try_reserve; then
            RESERVED=true
        fi
    } 9>"$LOCK_FILE"

    if [[ "$RESERVED" == "true" ]]; then
        break
    fi

    # Not enough VRAM — report and retry
    if [[ $i -eq 1 ]]; then
        echo "GPU: Waiting for VRAM (need ${VRAM}MB, caller=$CALLER, job=$JOB_ID)..." >&2
    fi

    if [[ $i -eq $MAX_RETRIES ]]; then
        echo "ERROR: GPU timeout after $((MAX_RETRIES * RETRY_DELAY))s. Need ${VRAM}MB, not enough available." >&2
        exit 1
    fi

    sleep "$RETRY_DELAY"
done

if [[ "$RESERVED" != "true" ]]; then
    echo "ERROR: Failed to reserve GPU VRAM." >&2
    exit 1
fi

echo "GPU: Reserved ${VRAM}MB (caller=$CALLER, job=$JOB_ID)" >&2

# --- Execute command with timeout ---
timeout "$TIMEOUT" "${CMD[@]}"
EXIT_CODE=$?

if [[ $EXIT_CODE -eq 124 ]]; then
    echo "ERROR: GPU job timed out after ${TIMEOUT}s (job=$JOB_ID)" >&2
fi

exit $EXIT_CODE
