#!/usr/bin/env bash
# Render every ```mermaid block in the repo's Markdown with mermaid-cli.
# A syntax error in any diagram fails the run (GitHub would show it broken).
set -euo pipefail
cd "$(dirname "$0")/.."
out=$(mktemp -d)
cat > "$out/puppeteer.json" <<'JSON'
{ "args": ["--no-sandbox", "--disable-setuid-sandbox"] }
JSON
mapfile -t files < <(grep -rl --include='*.md' '^```mermaid' . | grep -v node_modules | sort)
echo "Checking ${#files[@]} file(s) with Mermaid diagrams"
for f in "${files[@]}"; do
  echo "::group::$f"
  npx -y -p @mermaid-js/mermaid-cli@12.2.0 mmdc -q -p "$out/puppeteer.json" \
    -i "$f" -o "$out/$(echo "$f" | tr '/.' '__').md"
  echo "::endgroup::"
done
echo "All diagrams rendered"
