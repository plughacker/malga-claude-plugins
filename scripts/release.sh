#!/usr/bin/env bash
# Cut a GitHub release using only the matching CHANGELOG section as notes.
#
# Usage:
#   ./scripts/release.sh                                  # version from plugin.json, title = tag
#   ./scripts/release.sh v0.8.0                           # explicit tag, title = tag
#   ./scripts/release.sh v0.8.0 "v0.8.0 — short title"   # explicit tag + title
#
# Behaviour:
#   1. Reads version from malga-integration-toolkit/.claude-plugin/plugin.json (or argv).
#   2. Extracts the matching section from CHANGELOG.md.
#   3. Calls `gh release create <tag> malga-integration-toolkit.plugin --notes-file <tmpfile>`.
#
# Requires: gh CLI authenticated, .plugin file at repo root, CHANGELOG entry for the version.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PLUGIN_FILE="malga-integration-toolkit.plugin"
CHANGELOG="CHANGELOG.md"
MANIFEST="malga-integration-toolkit/.claude-plugin/plugin.json"

if [[ $# -ge 1 ]]; then
  TAG="$1"
  # Strip the leading v if present, then re-add for the tag
  VERSION="${TAG#v}"
else
  if ! command -v python3 >/dev/null; then
    echo "python3 required to read plugin.json (or pass the tag as argv)"
    exit 1
  fi
  VERSION="$(python3 -c "import json; print(json.load(open('$MANIFEST'))['version'])")"
  TAG="v$VERSION"
fi

echo "→ Releasing $TAG (version $VERSION)"

if [[ ! -f "$PLUGIN_FILE" ]]; then
  echo "missing $PLUGIN_FILE — repackage the plugin first" >&2
  exit 1
fi

# Extract the section: from `## [VERSION]` line, up to (but not including) the next `## [` line.
NOTES_TMP="$(mktemp -t malga-release-notes.XXXXXX.md)"
awk -v version="$VERSION" '
  /^## \[/ {
    if (capturing) { exit }
    if ($0 ~ "^## \\[" version "\\]") { capturing=1; print; next }
  }
  capturing { print }
' "$CHANGELOG" > "$NOTES_TMP"

if [[ ! -s "$NOTES_TMP" ]]; then
  echo "no CHANGELOG section found for version $VERSION" >&2
  rm -f "$NOTES_TMP"
  exit 1
fi

echo "----------------- RELEASE NOTES PREVIEW -----------------"
cat "$NOTES_TMP"
echo "---------------------------------------------------------"
echo ""
read -r -p "Create release $TAG with the notes above? [y/N] " ans
case "$ans" in
  y|Y|yes|YES) ;;
  *) echo "aborted"; rm -f "$NOTES_TMP"; exit 1 ;;
esac

# Title: optional argv[2], else just the tag.
TITLE="${2:-$TAG}"

gh release create "$TAG" "$PLUGIN_FILE" \
  --title "$TITLE" \
  --notes-file "$NOTES_TMP"

rm -f "$NOTES_TMP"
echo "✓ Released $TAG"
