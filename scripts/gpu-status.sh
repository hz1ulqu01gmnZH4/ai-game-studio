#!/bin/bash
# GPU Status — shows current reservations, available VRAM, and recent history.
# Used by マネージャー for dashboard updates.
#
# Usage: scripts/gpu-status.sh

STUDIO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RESERVATIONS_DIR="$STUDIO_DIR/queue/gpu/reservations"
HISTORY_DIR="$STUDIO_DIR/queue/gpu/history"

echo "=== GPU Hardware ==="
if nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free,utilization.gpu --format=csv,noheader 2>/dev/null; then
    :
else
    echo "(nvidia-smi unavailable)"
fi

echo ""
echo "=== Active Reservations ==="
TOTAL_RESERVED=0
HAS_RESERVATIONS=false

for f in "$RESERVATIONS_DIR"/*.json; do
    [[ -f "$f" ]] || continue

    # Check if process is alive
    pid=$(grep -o '"pid":[0-9]*' "$f" 2>/dev/null | grep -o '[0-9]*' || echo "")
    if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
        echo "  STALE (pid $pid dead): $(cat "$f")"
        rm -f "$f"
        continue
    fi

    HAS_RESERVATIONS=true
    vram=$(grep -o '"vram_mb":[0-9]*' "$f" 2>/dev/null | grep -o '[0-9]*' || echo "0")
    TOTAL_RESERVED=$((TOTAL_RESERVED + vram))
    echo "  $(cat "$f")"
done

if [[ "$HAS_RESERVATIONS" != "true" ]]; then
    echo "  (none)"
fi

echo ""
echo "Total reserved: ${TOTAL_RESERVED}MB"

# Show effective available
FREE_VRAM=$(nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
if [[ -n "$FREE_VRAM" ]]; then
    EFFECTIVE=$((FREE_VRAM - TOTAL_RESERVED))
    [[ $EFFECTIVE -lt 0 ]] && EFFECTIVE=0
    echo "Free VRAM: ${FREE_VRAM}MB | Effective available: ${EFFECTIVE}MB"
fi

echo ""
echo "=== Recent History (last 5) ==="
HISTORY_FILES=$(ls -t "$HISTORY_DIR"/*.json 2>/dev/null | head -5)
if [[ -n "$HISTORY_FILES" ]]; then
    while IFS= read -r f; do
        echo "  $(cat "$f")"
    done <<< "$HISTORY_FILES"
else
    echo "  (none)"
fi
