#!/bin/bash
# KGP SessionStart hook — surface in-flight PRP state so a fresh session knows
# what's active without a manual /KGP:context-prime. Silent when nothing to report.

PRP_DIR="PRPs"
PROGRESS_FILE=".claude/prp-task-progress.md"

[ -d "$PRP_DIR" ] || exit 0

PRPS=$(ls -1 "$PRP_DIR"/*.md 2>/dev/null | head -8) || true
[ -n "$PRPS" ] || exit 0

echo "[KGP] PRP files present in this project:"
while IFS= read -r f; do
  echo "  - $f"
done <<< "$PRPS"

if [ -f "$PROGRESS_FILE" ]; then
  DONE=$(grep -c "status: done" "$PROGRESS_FILE" 2>/dev/null || echo 0)
  BLOCKED=$(grep -c "status: blocked" "$PROGRESS_FILE" 2>/dev/null || echo 0)
  echo "[KGP] In-flight execution state found ($PROGRESS_FILE): $DONE done, $BLOCKED blocked. A previous /KGP:prp-execute run may be resumable."
else
  echo "[KGP] No execution in flight. Run /KGP:prp-validate then /KGP:prp-execute to start one."
fi

exit 0
