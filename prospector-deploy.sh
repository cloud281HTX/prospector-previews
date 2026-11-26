#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# prospector-deploy — push current previews to GitHub Pages (OIDC deploy).
#
# Usage:
#   ./prospector-deploy.sh "<batch-folder>" ["commit message"]
#
# Requires:
#   - repo git remote set (origin -> git@github-prospector-previews:<YOU>/prospector-previews.git)
#   - "github-prospector-previews" SSH alias using UNSEEN single-repo deploy key
#     ~/.ssh/sk-prospector-previews (writable to ONLY this repo).
#
# The workflow .github/workflows/deploy.yml does the Pages deploy with an
# ephemeral OIDC token. This script only stages + pushes the static files.
# No web token is stored anywhere on this machine.
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BATCH="${1:-}"
MSG="${2:-previews update}"

if [ -z "$BATCH" ]; then
  echo "usage: $0 <batch-folder> [commit message]" >&2
  echo "e.g.:   $0 ~/outreach/2026-11-26_Scottsdale_AZ_Kitchen_Remodelers" >&2
  exit 1
fi
if [ ! -d "$BATCH" ]; then
  echo "ERROR: batch folder not found: $BATCH" >&2
  exit 1
fi

cd "$REPO_DIR"

# Stage the html previews from the batch into public/
echo ">> staging previews from $BATCH"
count=0
for f in "$BATCH"/*.html; do
  [ -e "$f" ] || continue
  cp "$f" public/
  count=$((count+1))
done
if [ "$count" -eq 0 ]; then
  echo "ERROR: no .html files in $BATCH" >&2
  exit 1
fi
echo "   staged $count html file(s)"

git add -A
git commit -m "$MSG" >/dev/null 2>&1 || echo "   (nothing to commit)"
echo ">> pushing via deploy key (single-repo SSH)"
git push origin main
echo ">> done. Live at https://<your-account>.github.io/prospector-previews/"
