#!/usr/bin/env bash
urls=(
  "biliroaming https://github.com/yujincheng08/BiliRoaming/archive/5653b06.tar.gz"
  "haven https://github.com/GlassHaven/Haven/archive/refs/tags/v5.68.41.tar.gz"
  "immich https://github.com/immich-app/immich/archive/refs/tags/v3.0.2.tar.gz"
  "lumo https://github.com/ProtonLumo/android-lumo/archive/refs/tags/2.0.2-nogms.tar.gz"
  "bitwarden-android https://github.com/bitwarden/android/archive/refs/tags/v2026.6.1-bwpm.tar.gz"
  "bitwarden-authenticator https://github.com/bitwarden/android/archive/refs/tags/v2026.6.1-bwa.tar.gz"
  "gadgetbridge https://codeberg.org/Freeyourgadget/Gadgetbridge/archive/0.92.2.tar.gz"
)

for entry in "${urls[@]}"; do
  name="${entry%% *}"
  url="${entry#* }"
  echo -n "$name: "
  hash=$(nix-prefetch-url --unpack "$url" 2>/dev/null)
  nix hash to-sri --type sha256 "$hash"
done
