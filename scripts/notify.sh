#!/bin/bash
# Notify a tmux pane with a message. Handles the two-call send-keys protocol.
#
# Usage: scripts/notify.sh <pane_id> <message>
# Example: scripts/notify.sh %60 "Task task_005 completed. Check queue/done/task_005.md"
#
# Reads pane targets: scripts/notify.sh manager "Task done"
#   Looks up "manager" in config/pane_targets.yaml automatically.

set -euo pipefail

STUDIO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGET="$1"
shift
MESSAGE="$*"

# If target is a role name (not a pane ID like %60), resolve it
if [[ ! "$TARGET" =~ ^% ]]; then
    PANE_ID=$(grep "^${TARGET}:" "$STUDIO_DIR/config/pane_targets.yaml" | head -1 | sed 's/.*"\(.*\)"/\1/')
    if [ -z "$PANE_ID" ]; then
        echo "ERROR: No pane found for role '$TARGET' in config/pane_targets.yaml" >&2
        exit 1
    fi
else
    PANE_ID="$TARGET"
fi

tmux send-keys -t "$PANE_ID" "$MESSAGE"
sleep 0.3
tmux send-keys -t "$PANE_ID" Enter
