#!/usr/bin/env bash
set -euo pipefail

input="${1:-deps.json}"
tmp="$(mktemp)"

jq -c '
  to_entries[]
' "$input" | while read -r outer; do
  key="$(jq -r '.key' <<<"$outer")"

  jq -c '.value | to_entries[]' <<<"$outer" | while read -r inner; do
    filename="$(jq -r '.key' <<<"$inner")"
    url="$(jq -r '.value.url' <<<"$inner")"

    hash="$(
      nix store prefetch-file "$url" --json \
        | jq -r '.hash'
    )"

    jq \
      --arg k "$key" \
      --arg f "$filename" \
      --arg h "$hash" \
      '
      .[$k][$f].hash = $h
      ' "$input" > "$tmp"

    mv "$tmp" "$input"
  done
done