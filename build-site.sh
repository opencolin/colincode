#!/bin/sh
# Render the site for one brand into dist/. The same script and page are
# published twice: colincode.org installs `colin`, luxcode.org installs `lux`.
#   BRAND=colincode ./build-site.sh   (default)
#   BRAND=luxcode   ./build-site.sh
# Vercel runs this as the build command; each project sets BRAND in its env.
set -eu
BRAND="${BRAND:-colincode}"
case "$BRAND" in
  colincode) CMD=colin; SITE=colincode.org; OTHER=luxcode;   OTHER_SITE=luxcode.org ;;
  luxcode)   CMD=lux;   SITE=luxcode.org;   OTHER=colincode; OTHER_SITE=colincode.org ;;
  *) echo "unknown BRAND '$BRAND' (colincode | luxcode)" >&2; exit 2 ;;
esac
cd "$(dirname "$0")"
rm -rf dist && mkdir -p dist/assets
cp site/assets/* dist/assets/
# Each brand has its own page: colincode's is site/index.html, luxcode's (Luxor's
# look) is site/luxcode.html. Everything else is shared and brand-substituted.
for f in site/*; do
  case "$f" in
    site/assets) continue ;;
    site/index.html)   [ "$BRAND" = colincode ] || continue ;;
    site/luxcode.html) [ "$BRAND" = luxcode ] || continue; dest=index.html ;;
    site/favicon-lux.svg) [ "$BRAND" = luxcode ] || continue; cp "$f" dist/favicon.svg; continue ;;
    site/favicon.svg)  [ "$BRAND" = colincode ] || continue ;;
  esac
  case "$f" in
    *.svg) cp "$f" "dist/$(basename "$f")" ;;
    *) perl -pe "s/colincode\\.org/$SITE/g; s/colincode/$BRAND/g; s/\\bcolin\\b/$CMD/g; s/\\@\\@OTHER_SITE\\@\\@/$OTHER_SITE/g; s/\\@\\@OTHER_BRAND\\@\\@/$OTHER/g" "$f" > "dist/${dest:-$(basename "$f")}"; dest= ;;
  esac
done
cp colin "dist/$CMD"
echo "built dist/ for $BRAND ($CMD, https://$SITE)"
