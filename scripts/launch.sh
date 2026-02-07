#!/bin/bash
# AI Game Studio — Launch Script
# Deploys Director + Manager + specialist agents in tmux windows.

# Usage:
# ./scripts/launch.sh [options] [roles...]
# ./scripts/launch.sh asset_generator gameplay_programmer qa_lead
# ./scripts/launch.sh -s # Setup only (no Claude launch)
# ./scripts/launch.sh -a # All specialist roles
# ./scripts/launch.sh -h # Help

# Panes are ALWAYS created for all specialists (manager + 9 roles).
# The [roles...] argument controls which panes get Claude launched.
# If no roles specified, launches Director + Manager only.
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
            echo " -s, --setup-only Create tmux layout only (no Claude launch)"
            echo " -a, --all Launch Claude in all specialist panes"
            echo " -h, --help Show this help"
            echo ""
            echo "Panes are always created for all specialists."
            echo "Roles control which panes get Claude launched."
            echo ""
            echo "Examples:"
            echo " ./scripts/launch.sh # Director + Manager only"
            echo " ./scripts/launch.sh asset_generator qa_lead # Director + Manager + 2 specialists"
            echo " ./scripts/launch.sh -a # All roles"
            echo ""
            echo "Available specialist roles:"
            for f in "$STUDIO_DIR"/instructions/*.md; do
                name=$(basename "$f" .md)
                [ "$name" = "director" ] && continue
                [ "$name" = "manager" ] && continue
                [[ "$name" == _* ]] && continue
                echo " - $name"
            done
            echo ""
            echo "Tmux navigation:"
            echo " Ctrl-b n / Ctrl-b p Next/previous window"
            echo " Ctrl-b <number> Jump to window by index"
            echo " Ctrl-b w Window list"
            echo " Ctrl-b o Next pane in current window"
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

# Remaining args are role names to launch Claude in
LAUNCH_ROLES=("$@")

# Collect ALL specialist roles (panes are always created for all)
ALL_SPECIALIST_ROLES=
for f in "$STUDIO_DIR"/instructions/*.md; do
    name=$(basename "$f" .md)
    [ "$name" = "director" ] && continue
    [ "$name" = "manager" ] && continue
    [[ "$name" == _* ]] && continue
    ALL_SPECIALIST_ROLES+=("$name")
done

# If --all, launch Claude in every specialist pane
if [ "$ALL_ROLES" = true ]; then
    LAUNCH_ROLES=("${ALL_SPECIALIST_ROLES[@]}")
fi

# Validate launch role instruction files exist
for role in "${LAUNCH_ROLES[@]}"; do
    if [ ! -f "$STUDIO_DIR/instructions/${role}.md" ]; then
        echo "ERROR: No instruction file for role '$role' at instructions/${role}.md" >&2
        exit 1
    fi
done

# --- Color helpers ---
log_info { echo -e "\033[1;33m[info]\033[0m $1"; }
log_success { echo -e "\033[1;32m[done]\033[0m $1"; }
log_action { echo -e "\033[1;31m[act]\033[0m $1"; }

# --- Persona lookup from studio.yaml ---
# Returns the Japanese display name for a role (e.g., "" for "manager")
get_persona_name {
    local role="$1"
    local yaml="$STUDIO_DIR/config/studio.yaml"
    # Extract the name field under workers.<role>.name, take just the Japanese part before " ("
    # Two-phase: first enter the workers: section, then find the role and its name field
    local full_name
    full_name=$(awk '/^ workers:/{w=1} w && /^ '"${role}"':/{found=1} found && /name:/{print; exit}' "$yaml" \
        | sed 's/.*name: *"\(.*\)"/\1/' | sed 's/ *(.*//')
    if [ -n "$full_name" ]; then
        echo "$full_name"
    else
        echo "$role"
    fi
}

# Helper: check if a role is in LAUNCH_ROLES
is_launch_role {
    local needle="$1"
    for r in "${LAUNCH_ROLES[@]}"; do
        [ "$r" = "$needle" ] && return 0
    done
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 0: Bootstrap personas into universal-memory (idempotent)
# ═══════════════════════════════════════════════════════════════════════════════
log_info "Bootstrapping worker personas into universal-memory..."
python3 "$STUDIO_DIR/scripts/bootstrap-personas.py" 2>&1 | while IFS= read -r line; do log_info " $line"; done
log_success " Personas ready in memory.db"

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
    tmux kill-window -t "${CURRENT_SESSION}:director" 2>/dev/null && log_info " Removed old 'director' window" || true
    tmux kill-window -t "${CURRENT_SESSION}:workers" 2>/dev/null && log_info " Removed old 'workers' window" || true
else
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null && log_info " Removed old '$SESSION_NAME' session" || true
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
DIRECTOR_PERSONA=$(get_persona_name "director")
tmux select-pane -t "$DIRECTOR_PANE" -T "director"
tmux send-keys -t "$DIRECTOR_PANE" "cd '$STUDIO_DIR' && export PS1='(\[\033[1;35m\]監督 ${DIRECTOR_PERSONA}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ ' && clear"
sleep 0.3
tmux send-keys -t "$DIRECTOR_PANE" Enter
# Director gets dark background
tmux select-pane -t "$DIRECTOR_PANE" -P 'bg=#002b36' 2>/dev/null || true

log_success " Director window created"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 4: Create Workers window (Manager + ALL specialists — always all panes)
# ═══════════════════════════════════════════════════════════════════════════════
# Worker list: manager + all specialists (always)
WORKER_NAMES=("manager" "${ALL_SPECIALIST_ROLES[@]}")
WORKER_COUNT=${#WORKER_NAMES[@]}
log_action "Creating Workers window ($WORKER_COUNT panes: Manager + ${#ALL_SPECIALIST_ROLES[@]} specialists)..."

if [ "$IN_TMUX" = true ]; then
    tmux new-window -n "workers" -c "$STUDIO_DIR"
    WORKERS_TARGET="${CURRENT_SESSION}:workers"
else
    tmux new-window -t "$SESSION_NAME" -n "workers" -c "$STUDIO_DIR"
    WORKERS_TARGET="${SESSION_NAME}:workers"
fi

# 3-column grid layout (from multi-agent-shogun/shutsujin_departure.sh)
PANE_IDS=
PANE_IDS+=($(tmux display-message -t "$WORKERS_TARGET" -p '#{pane_id}'))

# Create 3 columns
PANE_IDS+=($(tmux split-window -h -t "$WORKERS_TARGET" -c "$STUDIO_DIR" -P -F '#{pane_id}'))
PANE_IDS+=($(tmux split-window -h -t "$WORKERS_TARGET" -c "$STUDIO_DIR" -P -F '#{pane_id}'))

# Subdivide columns into rows
# Column 1 (PANE_IDS[0]): 4 rows → manager + 3 specialists
PANE_IDS+=($(tmux split-window -v -t "${PANE_IDS[0]}" -c "$STUDIO_DIR" -P -F '#{pane_id}'))
PANE_IDS+=($(tmux split-window -v -t "${PANE_IDS[0]}" -c "$STUDIO_DIR" -P -F '#{pane_id}'))
PANE_IDS+=($(tmux split-window -v -t "${PANE_IDS[0]}" -c "$STUDIO_DIR" -P -F '#{pane_id}'))

# Column 2 (PANE_IDS[1]): 3 rows → 3 specialists
PANE_IDS+=($(tmux split-window -v -t "${PANE_IDS[1]}" -c "$STUDIO_DIR" -P -F '#{pane_id}'))
PANE_IDS+=($(tmux split-window -v -t "${PANE_IDS[1]}" -c "$STUDIO_DIR" -P -F '#{pane_id}'))

# Column 3 (PANE_IDS[2]): 3 rows → 3 specialists
PANE_IDS+=($(tmux split-window -v -t "${PANE_IDS[2]}" -c "$STUDIO_DIR" -P -F '#{pane_id}'))
PANE_IDS+=($(tmux split-window -v -t "${PANE_IDS[2]}" -c "$STUDIO_DIR" -P -F '#{pane_id}'))

# Apply tiled layout for even distribution
tmux select-layout -t "$WORKERS_TARGET" tiled

# Get sorted pane IDs (tmux display order)
readarray -t SORTED_WORKER_PANES < <(tmux list-panes -t "$WORKERS_TARGET" -F '#{pane_id}')

# Set pane titles and color-coded prompts with persona names
# Pane 0: Manager (red), Panes 1+: specialists (blue)
WORKER_COLORS=("1;31" $(printf '1;34 %.0s' $(seq 1 ${#ALL_SPECIALIST_ROLES[@]})))
read -ra WORKER_COLORS <<< "${WORKER_COLORS[*]}"

for i in $(seq 0 $((WORKER_COUNT - 1))); do
    pane_id="${SORTED_WORKER_PANES[@]:$i:1}"
    color="${WORKER_COLORS[@]:$i:1}"
    name="${WORKER_NAMES[@]:$i:1}"
    persona=$(get_persona_name "$name")
    tmux select-pane -t "$pane_id" -T "$name"
    tmux send-keys -t "$pane_id" "cd '$STUDIO_DIR' && export PS1='(\[\033[${color}m\]${persona}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ ' && clear"
    sleep 0.3
    tmux send-keys -t "$pane_id" Enter
done

log_success " Workers window created"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 5: Save pane ID mapping (for inter-agent communication)
# ═══════════════════════════════════════════════════════════════════════════════
log_info "Saving pane ID mapping to config/pane_targets.yaml..."
mkdir -p "$STUDIO_DIR/config"

{
    echo "# Auto-generated pane targets — DO NOT EDIT MANUALLY"
    echo "# Generated at: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# Use role names (keys) with scripts/notify.sh for all tmux communication."
    echo "# Example: scripts/notify.sh manager \"Task completed\""
    echo ""
    echo "director: \"$DIRECTOR_PANE\" # $(get_persona_name director)"
    for i in $(seq 0 $((WORKER_COUNT - 1))); do
        wname="${WORKER_NAMES[@]:$i:1}"
        echo "${wname}: \"${SORTED_WORKER_PANES[@]:$i:1}\" # $(get_persona_name "$wname")"
    done
} > "$STUDIO_DIR/config/pane_targets.yaml"

log_success " Pane mapping saved"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 6: Launch Claude Code in each pane (unless --setup-only)
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$SETUP_ONLY" = false ]; then
    log_action "Launching Claude Code..."

    # Role instructions are injected via --append-system-prompt so they
    # persist through context compression (unlike user messages which get lost).
    # MCP servers (universal-memory + qwen3-tts) are attached via --mcp-config.
    MCP_CONFIG="$STUDIO_DIR/config/mcp_studio.json"

    # Director — Opus with extended thinking + system prompt role + MCP
    DIRECTOR_PROMPT="$STUDIO_DIR/instructions/director.md"
    tmux send-keys -t "$DIRECTOR_PANE" "claude --dangerously-skip-permissions --model opus --mcp-config '$MCP_CONFIG' --append-system-prompt \"\$(cat '$DIRECTOR_PROMPT')\""
    sleep 0.3
    tmux send-keys -t "$DIRECTOR_PANE" Enter
    log_info " Director: opus + instructions/director.md (system prompt)"
    sleep 1

    # Manager — always launched
    MANAGER_PROMPT="$STUDIO_DIR/instructions/manager.md"
    manager_pane="${SORTED_WORKER_PANES[@]:0:1}"
    tmux send-keys -t "$manager_pane" "claude --dangerously-skip-permissions --model sonnet --mcp-config '$MCP_CONFIG' --append-system-prompt \"\$(cat '$MANAGER_PROMPT')\""
    sleep 0.3
    tmux send-keys -t "$manager_pane" Enter
    log_info " Manager: sonnet + instructions/manager.md (system prompt)"

    # Specialists — only launch in roles specified by args
    for i in $(seq 0 $((${#ALL_SPECIALIST_ROLES[@]} - 1))); do
        role="${ALL_SPECIALIST_ROLES[@]:$i:1}"
        pane_idx=$((i + 1))
        if is_launch_role "$role"; then
            ROLE_PROMPT="$STUDIO_DIR/instructions/${role}.md"
            spec_pane="${SORTED_WORKER_PANES[@]:$pane_idx:1}"
            tmux send-keys -t "$spec_pane" "claude --dangerously-skip-permissions --mcp-config '$MCP_CONFIG' --append-system-prompt \"\$(cat '$ROLE_PROMPT')\""
            sleep 0.3
            tmux send-keys -t "$spec_pane" Enter
            log_info " $role: sonnet + instructions/${role}.md (system prompt)"
        else
            log_info " $role: (pane ready, Claude not launched)"
        fi
    done

    log_success " Claude instances launched (roles injected as system prompts)"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 7: Summary
# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo " ┌──────────────────────────────────────────────────────┐"
echo " │ Layout │"
echo " └──────────────────────────────────────────────────────┘"
echo ""

if [ "$IN_TMUX" = true ]; then
    echo " Session: $CURRENT_SESSION (existing)"
else
    echo " Session: $SESSION_NAME (new)"
fi

echo ""
echo " [director] window — 監督 (Opus, extended thinking)"
echo " ┌──────────────────────────────────────────────────────┐"
echo " │ 監督 (Director) — creative authority, phase scope │"
echo " └──────────────────────────────────────────────────────┘"
echo ""
echo " [workers] window — マネージャー + specialists (${WORKER_COUNT} panes)"
echo " ┌──────────────┬──────────────┬──────────────┐"

# Build 3-column display (4-3-3 grid matching pane layout)
COL1_SIZE=4
COL2_SIZE=3
COL3_SIZE=3
MAX_ROWS=4

for row in $(seq 0 $((MAX_ROWS - 1))); do
    # Column 1
    idx1=$row
    if [ "$idx1" -lt "$COL1_SIZE" ]; then
        name1="${WORKER_NAMES[@]:$idx1:1}"
        if [ "$name1" = "manager" ] || is_launch_role "$name1" 2>/dev/null; then
            marker1="*"
        else
            marker1=" "
        fi
        col1=$(printf "%-12s %s" "$name1" "$marker1")
    else
        col1=$(printf "%-14s" "")
    fi

    # Column 2
    idx2=$((COL1_SIZE + row))
    if [ "$idx2" -lt "$((COL1_SIZE + COL2_SIZE))" ]; then
        name2="${WORKER_NAMES[@]:$idx2:1}"
        if is_launch_role "$name2" 2>/dev/null; then
            marker2="*"
        else
            marker2=" "
        fi
        col2=$(printf "%-12s %s" "$name2" "$marker2")
    else
        col2=$(printf "%-14s" "")
    fi

    # Column 3
    idx3=$((COL1_SIZE + COL2_SIZE + row))
    if [ "$idx3" -lt "$WORKER_COUNT" ]; then
        name3="${WORKER_NAMES[@]:$idx3:1}"
        if is_launch_role "$name3" 2>/dev/null; then
            marker3="*"
        else
            marker3=" "
        fi
        col3=$(printf "%-12s %s" "$name3" "$marker3")
    else
        col3=$(printf "%-14s" "")
    fi

    printf " │ %s│ %s│ %s│\n" "$col1" "$col2" "$col3"

    if [ "$row" -lt "$((MAX_ROWS - 1))" ]; then
        echo " ├──────────────┼──────────────┼──────────────┤"
    fi
done

echo " └──────────────┴──────────────┴──────────────┘"
echo " (* = Claude launched)"
echo ""

if [ "$SETUP_ONLY" = true ]; then
    echo " Setup-only mode: Claude Code not launched."
    echo " Launch manually in each pane."
    echo ""
fi

echo " Navigation:"
if [ "$IN_TMUX" = true ]; then
    echo " Ctrl-b n / Ctrl-b p Next/previous window"
    echo " Ctrl-b <number> Jump to window by index"
    echo " Ctrl-b w Window list"
    echo " Ctrl-b o Next pane (in workers)"
else
    echo " tmux attach -t $SESSION_NAME"
    echo " Then: Ctrl-b n/p to switch windows, Ctrl-b o to switch panes"
fi
echo ""
echo " Pane targets: config/pane_targets.yaml"
echo " GPU status: scripts/gpu-status.sh"
echo ""
echo "=== Studio Ready ==="
echo ""
