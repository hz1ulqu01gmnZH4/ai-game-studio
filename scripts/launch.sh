#!/bin/bash
# AI Game Studio Launcher
# Usage: ./scripts/launch.sh [roles...]
# Example: ./scripts/launch.sh asset_generator gameplay_programmer qa_lead art_director
# If no roles specified, launches Director + Manager only (minimal setup)

STUDIO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROLES=("$@")

echo "=== AI Game Studio ==="
echo "Directory: $STUDIO_DIR"
echo ""

# Always launch Director (Opus, extended thinking)
echo "Starting 監督 (Director) — Opus, extended thinking..."
tmux new-session -d -s director -n director
tmux send-keys -t director "cd \"$STUDIO_DIR\" && claude --model opus" Enter
sleep 2
tmux send-keys -t director "/read instructions/director.md" Enter

# Always launch Manager (Sonnet, thinking off)
echo "Starting マネージャー (Manager) — Sonnet, thinking off..."
tmux new-session -d -s studio -n workers
tmux send-keys -t studio:workers.0 "cd \"$STUDIO_DIR\" && claude --model sonnet" Enter
sleep 1
tmux send-keys -t studio:workers.0 "/read instructions/manager.md" Enter

# Launch requested specialist roles
if [ ${#ROLES[@]} -eq 0 ]; then
    echo ""
    echo "No specialist roles specified. Director + Manager only."
    echo "To add specialists: ./scripts/launch.sh asset_generator gameplay_programmer qa_lead"
else
    PANE=1
    for role in "${ROLES[@]}"; do
        INSTRUCTION="$STUDIO_DIR/instructions/${role}.md"
        if [ ! -f "$INSTRUCTION" ]; then
            echo "WARNING: No instruction file for role '$role' at $INSTRUCTION — skipping"
            continue
        fi
        echo "Starting $role..."
        tmux split-window -t studio:workers
        tmux send-keys -t studio:workers.$PANE \
            "cd \"$STUDIO_DIR\" && claude" Enter
        sleep 1
        tmux send-keys -t studio:workers.$PANE \
            "/read instructions/${role}.md" Enter
        ((PANE++))
    done
    tmux select-layout -t studio:workers tiled
fi

echo ""
echo "=== Studio Launched ==="
echo "  Director:    tmux attach -t director"
echo "  Workers:     tmux attach -t studio"
echo ""
echo "Available roles:"
for f in "$STUDIO_DIR"/instructions/*.md; do
    name=$(basename "$f" .md)
    [ "$name" = "director" ] && continue
    [ "$name" = "manager" ] && continue
    echo "  - $name"
done
