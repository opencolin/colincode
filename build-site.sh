#!/bin/sh
# Render the site for one brand into dist/. The same script and page are
# published twice: colincode.org installs `colin`, luxcode.org installs `lux`.
#   BRAND=colincode ./build-site.sh   (default)
#   BRAND=luxcode   ./build-site.sh
# Vercel runs this as the build command; each project sets BRAND in its env.
set -eu
BRAND="${BRAND:-colincode}"
case "$BRAND" in
  colincode) CMD=colin; SITE=colincode.org ;;
  luxcode)   CMD=lux;   SITE=luxcode.org ;;
  *) echo "unknown BRAND '$BRAND' (colincode | luxcode)" >&2; exit 2 ;;
esac
cd "$(dirname "$0")"
rm -rf dist && mkdir -p dist
for f in site/*; do
  case "$f" in
    *.svg) cp "$f" "dist/$(basename "$f")" ;;
    *) perl -pe "s/colincode\\.org/$SITE/g; s/colincode/$BRAND/g; s/\\bcolin\\b/$CMD/g" "$f" > "dist/$(basename "$f")" ;;
  esac
done
cp colin "dist/$CMD"
echo "built dist/ for $BRAND ($CMD, https://$SITE)"
