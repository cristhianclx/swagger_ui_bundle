#!/usr/bin/env bash
# Usage: ./scripts/fetch-swagger-ui.sh [VERSION]
# Example: ./scripts/fetch-swagger-ui.sh 5.31.0

set -e

VERSION="${1:-5.31.0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENDOR_DIR="$REPO_ROOT/swagger_ui_bundle/vendor"
TARGET_DIR="$VENDOR_DIR/swagger-ui-$VERSION"
TARBALL_URL="https://registry.npmjs.org/swagger-ui-dist/-/swagger-ui-dist-${VERSION}.tgz"
TMP_DIR=""

cleanup() {
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

echo "Fetching swagger-ui-dist@${VERSION} from npm registry..."
TMP_DIR="$(mktemp -d)"
curl -sSfL "$TARBALL_URL" -o "$TMP_DIR/pkg.tgz"

echo "Extracting..."
mkdir -p "$TMP_DIR/pkg"
tar -xzf "$TMP_DIR/pkg.tgz" -C "$TMP_DIR/pkg"

SRC="$TMP_DIR/pkg/package"
if [[ ! -d "$SRC" ]]; then
  SRC="$TMP_DIR/pkg"
fi

echo "Copying to $TARGET_DIR ..."
mkdir -p "$VENDOR_DIR"
rm -rf "$TARGET_DIR"
cp -a "$SRC" "$TARGET_DIR"

TEMPLATE="$SCRIPT_DIR/templates/index.j2"
if [[ -f "$TEMPLATE" ]]; then
  cp "$TEMPLATE" "$TARGET_DIR/index.j2"
  echo "Applied index.j2 template."
fi

echo "Removing npm/Node-only and doc files..."
for f in LICENSE NOTICE README.md package.json absolute-path.js index.js; do
  rm -f "$TARGET_DIR/$f"
done
rm -f "$TARGET_DIR"/log.*.txt "$TARGET_DIR"/*.LICENSE.txt 2>/dev/null || true

INIT_PY="$REPO_ROOT/swagger_ui_bundle/__init__.py"
if [[ -f "$INIT_PY" ]]; then
  sed -i "s|\"vendor/swagger-ui-[^\"]*\"|\"vendor/swagger-ui-$VERSION\"|" "$INIT_PY"
  echo "Updated swagger_ui_path in __init__.py to vendor/swagger-ui-$VERSION"
fi

echo "Done. Vendor path: $TARGET_DIR"
