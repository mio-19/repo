# Temporary Scripts

This document stores temporary scripts created to solve specific problems. These scripts should generally only be used when normal methods (such as update scripts) have failed.

## get_hashes.sh

This script was used to fetch the source tarball hashes for a list of applications to fix hash mismatch issues during package updates when `check_updates.py` failed to provide accurate hashes.

```bash
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
```

## bulk_nix_update.sh

This script was used to sequentially run `nix-update` for several packages.

```bash
#!/usr/bin/env bash
nix run nixpkgs#nix-update -- --flake --version 2026.9.1 apk_bitwarden-android
nix run nixpkgs#nix-update -- --flake --version 5.89.18 apk_haven
nix run nixpkgs#nix-update -- --flake --version 35.0.1 apk_nextcloud-android
nix run nixpkgs#nix-update -- --flake --version 1.18.1 morphe-cli
```
