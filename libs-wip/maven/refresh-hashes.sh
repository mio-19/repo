#!/usr/bin/env bash
set -euo pipefail

input="${1:-deps.json}"
tmp="$(mktemp)"

jq -r '.dependencies | keys[]' "$input" | while read -r dep; do
  url="$(jq -r --arg dep "$dep" '.dependencies[$dep].url' "$input")"

  sri_hash="$(
    nix store prefetch-file "$url" --json \
      | jq -r '.hash'
  )"

  hex_hash="$(
    nix hash convert --hash-algo sha256 --to base16 "$sri_hash"
  )"

  jq \
    --arg dep "$dep" \
    --arg hash "$hex_hash" \
    '
    .dependencies[$dep].sha256 = $hash
    ' "$input" > "$tmp"

  mv "$tmp" "$input"
done