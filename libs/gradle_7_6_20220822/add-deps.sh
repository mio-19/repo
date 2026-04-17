#!/usr/bin/env bash
set -euo pipefail

input="more.gradle.lock"
tmp="$(mktemp)"
cp "$input" "$tmp"

# Add com.gradle.enterprise.gradle.plugin:3.11.1
enterprise_files=(
  "com.gradle.enterprise.gradle.plugin-3.11.1.pom"
)

for filename in "${enterprise_files[@]}"; do
  key="com.gradle.enterprise:com.gradle.enterprise.gradle.plugin:3.11.1"
  url="https://plugins.gradle.org/m2/com/gradle/enterprise/com.gradle.enterprise.gradle.plugin/3.11.1/${filename}"
  hash=$(nix store prefetch-file "$url" --json | jq -r '.hash')
  
  echo "Adding $filename ($key)"
  jq --arg k "$key" --arg f "$filename" --arg h "$hash" --arg u "$url" '.[$k][$f] = {url: $u, hash: $h}' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
done

cp "$tmp" "$input"
echo "Done"
