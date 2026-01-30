#!/bin/bash
# AI Game Studio — Launch Script
# Deploys Director + Manager + specialist agents in tmux windows.
#
# Usage:
#   ./scripts/launch.sh [options] [roles...]
#   ./scripts/launch.sh asset_generator gameplay_programmer qa_lead
#   ./scripts/launch.sh -s                     # Setup only (no Claude launch)
#   ./scripts/launch.sh -a                     # All specialist roles
#   ./scripts/launch.sh -h                     # Help
#
# If no roles specified, launches Director + Manager only (minimal setup).
# When run inside tmux, creates windows in the current session.
# When run outside tmux, creates a new "gamestudio" session.

set -euo pipefail

STUDIO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSION_NAME="gamestudio"

# --- Options ---
SETUP_ONLY=false
ALL_ROLES=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--setup-only)
            SETUP_ONLY=true
            shift
            ;;
        -a|--all)
            ALL_ROLES=true
            shift
            ;;
        -h|--help)
            echo ""
            echo "AI Game Studio — Launch Script"
            echo ""
            echo "Usage: ./scripts/launch.sh [options] [roles...]"
            echo ""
            echo "Options:"
            echo "  -s, --setup-only  Create tmux layout only (no Claude launch)"
            echo "  -a, --all         Launch all specialist roles"
            echo "  -h, --help        Show this help"
            echo ""
            echo "Examples:"
            echo "  ./scripts/launch.sh                                  # Director + Manager only"
            echo "  ./scripts/launch.sh asset_generator qa_lead          # Director + Manager + 2 specialists"
            echo "  ./scripts/launch.sh -a                               # All roles"
            echo ""
            echo "Available specialist roles:"
            for f in "$STUDIO_DIR"/instructions/*.md; do
                name=$(basename "$f" .md)
                [ "$name" = "director" ] && continue
                [ "$name" = "manager" ] && continue
                echo "  - $name"
            done
            echo ""
            echo "Tmux navigation:"
            echo "  Ctrl-b n / Ctrl-b p    Next/previous window"
            echo "  Ctrl-b <number>        Jump to window by index"
            echo "  Ctrl-b w               Window list"
            echo "  Ctrl-b o               Next pane in current window"
            echo ""
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "ERROR: Unknown option '$1'" >&2
            echo "Usage: ./scripts/launch.sh -h" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Remaining args are role names
ROLES=("$@")

# If --all, collect all specialist roles
if [ "$ALL_ROLES" = true ]; then
    ROLES=()
    for f in "$STUDIO_DIR"/instructions/*.md; do
        name=$(basename "$f" .md)
        [ "$name" = "director" ] && continue
        [ "$name" = "manager" ] && continue
        ROLES+=("$name")
    done
fi

# Validate role instruction files exist
for role in "${ROLES[@]}"; do
    if [ ! -f "$STUDIO_DIR/instructions/${role}.md" ]; then
        echo "ERROR: No instruction file for role '$role' at instructions/${role}.md" >&2
        exit 1
    fi
done

# --- Color helpers ---
log_info()    { echo -e "\033[1;33m[info]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[done]\033[0m $1"; }
log_action()  { echo -e "\033[1;31m[act]\033[0m  $1"; }

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 1: Detect tmux context
# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo "=== AI Game Studio ==="
echo "Directory: $STUDIO_DIR"
echo ""

if [ -n "${TMUX:-}" ]; then
    IN_TMUX=true
    CURRENT_SESSION=$(tmux display-message -p '#{session_name}')
    log_info "Running inside tmux (session: $CURRENT_SESSION). Creating windows."
else
    IN_TMUX=false
    log_info "Running outside tmux. Creating session '$SESSION_NAME'."
fi

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 2: Clean up existing windows/sessions
# ═══════════════════════════════════════════════════════════════════════════════
log_info "Cleaning up previous studio layout..."

if [ "$IN_TMUX" = true ]; then
    tmux kill-window -t "${CURRENT_SESSION}:director" 2>/dev/null && log_info "  Removed old 'director' window" || true
    tmux kill-window -t "${CURRENT_SESSION}:workers" 2>/dev/null && log_info "  Removed old 'workers' window" || true
else
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null && log_info "  Removed old '$SESSION_NAME' session" || true
fi

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 3: Create Director window (1 pane — Opus, extended thinking)
# ═══════════════════════════════════════════════════════════════════════════════
log_action "Creating Director window..."

if [ "$IN_TMUX" = true ]; then
    tmux new-window -n "director" -c "$STUDIO_DIR"
    DIRECTOR_TARGET="${CURRENT_SESSION}:director"
else
    tmux new-session -d -s "$SESSION_NAME" -n "director" -c "$STUDIO_DIR"
    DIRECTOR_TARGET="${SESSION_NAME}:director"
fi

DIRECTOR_PANE=$(tmux display-message -t "$DIRECTOR_TARGET" -p '#{pane_id}')
tmux select-pane -t "$DIRECTOR_PANE" -T "director"
tmux send-keys -t "$DIRECTOR_PANE" "cd '$STUDIO_DIR' && export PS1='(\[\033[1;35m\]監督\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ ' && clear"
sleep 0.3
tmux send-keys -t "$DIRECTOR_PANE" Enter
# Director gets dark background
tmux select-pane -t "$DIRECTOR_PANE" -P 'bg=#002b36' 2>/dev/null || true

log_success "  Director window created"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 4: Create Workers window (Manager + specialists in panes)
# ═══════════════════════════════════════════════════════════════════════════════
# Worker count: 1 (Manager) + N (specialists)
WORKER_COUNT=$((1 + ${#ROLES[@]}))
log_action "Creating Workers window ($WORKER_COUNT panes: Manager + ${#ROLES[@]} specialists)..."

if [ "$IN_TMUX" = true ]; then
    tmux new-window -n "workers" -c "$STUDIO_DIR"
    WORKERS_TARGET="${CURRENT_SESSION}:workers"
else
    tmux new-window -t "$SESSION_NAME" -n "workers" -c "$STUDIO_DIR"
    WORKERS_TARGET="${SESSION_NAME}:workers"
fi

# First pane is Manager (already exists from new-window)
WORKER_PANE_IDS=()
WORKER_PANE_IDS+=($(tmux display-message -t "$WORKERS_TARGET" -p '#{pane_id}'))

# Create additional panes for specialists
for role in "${ROLES[@]}"; do
    WORKER_PANE_IDS+=($(tmux split-window -t "$WORKERS_TARGET" -c "$STUDIO_DIR" -P -F '#{pane_id}'))
done

# Apply tiled layout for even distribution
if [ "$WORKER_COUNT" -gt 1 ]; then
    tmux select-layout -t "$WORKERS_TARGET" tiled
fi

# Get sorted pane IDs (tmux display order)
readarray -t SORTED_WORKER_PANES < <(tmux list-panes -t "$WORKERS_TARGET" -F '#{pane_id}')

# Set pane titles and color-coded prompts
# Pane 0: Manager (red), Panes 1+: specialists (blue)
WORKER_NAMES=("manager" "${ROLES[@]}")
WORKER_LABELS=("マネージャー" "${ROLES[@]}")
WORKER_COLORS=("1;31" $(printf '1;34 %.0s' $(seq 1 ${#ROLES[@]})))
read -ra WORKER_COLORS <<< "${WORKER_COLORS[*]}"

for i in $(seq 0 $((WORKER_COUNT - 1))); do
    pane_id="${SORTED_WORKER_PANES[$i]}"
    tmux select-pane -t "$pane_id" -T "${WORKER_NAMES[$i]}"
    tmux send-keys -t "$pane_id" "cd '$STUDIO_DIR' && export PS1='(\[\033[${WORKER_COLORS[$i]}m\]${WORKER_LABELS[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ ' && clear"
    sleep 0.3
    tmux send-keys -t "$pane_id" Enter
done

log_success "  Workers window created"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 5: Save pane ID mapping (for inter-agent communication)
# ═══════════════════════════════════════════════════════════════════════════════
log_info "Saving pane ID mapping to config/pane_targets.yaml..."
mkdir -p "$STUDIO_DIR/config"

{
    echo "# Auto-generated pane targets — DO NOT EDIT MANUALLY"
    echo "# Generated at: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# Use these IDs for tmux send-keys commands"
    echo ""
    echo "director: \"$DIRECTOR_PANE\""
    echo "manager: \"${SORTED_WORKER_PANES[0]}\""
    for i in $(seq 0 $((${#ROLES[@]} - 1))); do
        echo "${ROLES[$i]}: \"${SORTED_WORKER_PANES[$((i + 1))]}\""
    done
} > "$STUDIO_DIR/config/pane_targets.yaml"

log_success "  Pane mapping saved"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 6: Launch Claude Code in each pane (unless --setup-only)
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$SETUP_ONLY" = false ]; then
    log_action "Launching Claude Code in all panes..."

    # Director — Opus with extended thinking
    tmux send-keys -t "$DIRECTOR_PANE" "claude --model opus"
    sleep 0.3
    tmux send-keys -t "$DIRECTOR_PANE" Enter
    log_info "  Director: claude --model opus"
    sleep 1

    # Manager — Sonnet (default)
    tmux send-keys -t "${SORTED_WORKER_PANES[0]}" "claude --model sonnet"
    sleep 0.3
    tmux send-keys -t "${SORTED_WORKER_PANES[0]}" Enter
    log_info "  Manager: claude --model sonnet"

    # Specialists — Sonnet (default)
    for i in $(seq 0 $((${#ROLES[@]} - 1))); do
        tmux send-keys -t "${SORTED_WORKER_PANES[$((i + 1))]}" "claude"
        sleep 0.3
        tmux send-keys -t "${SORTED_WORKER_PANES[$((i + 1))]}" Enter
        log_info "  ${ROLES[$i]}: claude"
    done

    log_success "  All Claude instances launched"
    echo ""

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 6.5: Load instruction files (after Claude is ready)
    # ═══════════════════════════════════════════════════════════════════════════
    log_action "Waiting for Claude to initialize..."
    sleep 15

    log_action "Loading instruction files..."

    # Director
    tmux send-keys -t "$DIRECTOR_PANE" "/read instructions/director.md"
    sleep 0.3
    tmux send-keys -t "$DIRECTOR_PANE" Enter
    log_info "  Director: instructions/director.md"
    sleep 2

    # Manager
    tmux send-keys -t "${SORTED_WORKER_PANES[0]}" "/read instructions/manager.md"
    sleep 0.3
    tmux send-keys -t "${SORTED_WORKER_PANES[0]}" Enter
    log_info "  Manager: instructions/manager.md"
    sleep 2

    # Specialists
    for i in $(seq 0 $((${#ROLES[@]} - 1))); do
        tmux send-keys -t "${SORTED_WORKER_PANES[$((i + 1))]}" "/read instructions/${ROLES[$i]}.md"
        sleep 0.3
        tmux send-keys -t "${SORTED_WORKER_PANES[$((i + 1))]}" Enter
        log_info "  ${ROLES[$i]}: instructions/${ROLES[$i]}.md"
        sleep 1
    done

    log_success "  All instruction files loaded"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 7: Summary
# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo "  ┌──────────────────────────────────────────────────────┐"
echo "  │  Layout                                              │"
echo "  └──────────────────────────────────────────────────────┘"
echo ""

if [ "$IN_TMUX" = true ]; then
    echo "  Session: $CURRENT_SESSION (existing)"
else
    echo "  Session: $SESSION_NAME (new)"
fi

echo ""
echo "  [director] window — 監督 (Opus, extended thinking)"
echo "  ┌──────────────────────────────────────────────────────┐"
echo "  │  監督 (Director)  — creative authority, phase scope  │"
echo "  └──────────────────────────────────────────────────────┘"
echo ""
echo "  [workers] window — マネージャー + specialists"
echo "  ┌──────────────────────────────────────────────────────┐"
printf "  │  マネージャー (Manager)  — delegation, no thinking  │\n"
for role in "${ROLES[@]}"; do
    printf "  │  %-50s │\n" "$role"
done
echo "  └──────────────────────────────────────────────────────┘"
echo ""

if [ "$SETUP_ONLY" = true ]; then
    echo "  Setup-only mode: Claude Code not launched."
    echo "  Launch manually in each pane."
    echo ""
fi

echo "  Navigation:"
if [ "$IN_TMUX" = true ]; then
    echo "    Ctrl-b n / Ctrl-b p       Next/previous window"
    echo "    Ctrl-b <number>           Jump to window by index"
    echo "    Ctrl-b w                  Window list"
    echo "    Ctrl-b o                  Next pane (in workers)"
else
    echo "    tmux attach -t $SESSION_NAME"
    echo "    Then: Ctrl-b n/p to switch windows, Ctrl-b o to switch panes"
fi
echo ""
echo "  Pane targets: config/pane_targets.yaml"
echo "  GPU status:   scripts/gpu-status.sh"
echo ""
echo "=== Studio Ready ==="
echo ""
