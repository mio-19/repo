# repo

This repository contains many llm generated glue code.

Note that distributing binaries built from this repository might be disallowed by copyright/trademark holders. This repository is only available as source code only.

Using this repository may result in data loss, boot loops, bricked devices, injuries due to exploded devices, dead SD cards, thermonuclear war, lawsuit, banned account, money loss, or you getting fired because the alarm app failed. By proceeding, you accept full responsibility for any issues that may arise.

Some nix files in this repository produce fully broken or mostly broken results.

android devices rom configurations

command examples:

```zsh
nix build -L --max-jobs 4 .#los.gta4xlwifi.ota -o gta4xlwifi.zip
nix build -L --max-jobs 4 .#los.gts7lwifi.ota -o gts7lwifi.zip
nix build -L --max-jobs 4 .#losNoCcache.gts7lwifi.ota -o gts7l.zip
nix build -L --max-jobs 4 .#los.gts7l.ota -o gts7l.zip
nix build -L --max-jobs 4 .#losNoCcache.gts7l.ota -o gts7l.zip
nix build -L --max-jobs 4 .#los.gts9wifi.ota -o gts9wifi.zip

nix build -L --max-jobs 4 .#los.enchilada.ota -o enchilada.zip
nix build -L --max-jobs 4 .#los.enchilada.img -o enchilada-img.zip
nix build -L --max-jobs 4 .#losNoCcache.enchilada.img -o enchilada-img.zip
nix build -L --max-jobs 4 .#los.enchilada_mainline.img -o enchilada_mainline-img.zip
nix build -L --max-jobs 4 .#los.utm.img -o utm-img.zip

nix build -L --max-jobs 4 .#los.dm3q_cola2261.ota -o dm3q.zip
nix build -L --max-jobs 4 .#los.gts9wifi.ota -o gts9wifi.zip

nix build -L --max-jobs 4 .#gos.akita.ota



nix build -L --max-jobs 4 .#los.gta4xlwifi.releaseScript -o release
./release ./keys-akita



nix build -L --max-jobs 4 .#gos.akita.releaseScript -o release && ./release ./keys-akita
nix build -L --max-jobs 4 .#gos.husky.releaseScript -o release && ./release ./keys-husky
nix build -L --max-jobs 4 .#gosNoCcache.husky.releaseScript -o release && ./release ./keys-husky
nix build -L --max-jobs 4 .#gos.tangorpro.releaseScript -o release && ./release ./keys-tangorpro
nix build -L --max-jobs 4 .#gosNoCcache.tangorpro.releaseScript -o release && ./release ./keys-tangorpro
nix build -L --max-jobs 4 .#gos.mustang.releaseScript -o release && ./release ./keys-mustang
nix build -L --max-jobs 4 .#gos.cheetah.releaseScript -o release && ./release ./keys-cheetah
nix build -L --max-jobs 4 .#gosNoCcache.cheetah.releaseScript -o release && ./release ./keys-cheetah
```

It is recommended to have OEM unlocking to be on in developer options when flashing new versions to avoid bricked devices.

generate keys/updating keys:

```zsh
nix build -L .#gos.akita.generateKeysScript -o generate-keys && ./generate-keys ./keys-akita
nix build -L .#gos.husky.generateKeysScript -o generate-keys && ./generate-keys ./keys-husky
nix build -L .#gos.tangorpro.generateKeysScript -o generate-keys && ./generate-keys ./keys-tangorpro
nix build -L .#gos.mustang.generateKeysScript -o generate-keys && ./generate-keys ./keys-mustang
nix build -L .#gos.cheetah.generateKeysScript -o generate-keys && ./generate-keys ./keys-cheetah
nix build -L .#gosNoCcache.cheetah.generateKeysScript -o generate-keys && ./generate-keys ./keys-cheetah
nix build -L .#los.gta4xlwifi.generateKeysScript -o generate-keys && ./generate-keys ./keys-gta4xlwifi
```

build kernels (for debugging and developement only):

```zsh
nix build -L .#gta4xlwifi -o gta4xlwifi

nix build -L .#gts7l_standalone -o gts7l

# GrapheneOS husky (Pixel 8 Pro) kernel dist files
nix build -L .#grapheneos-husky-kernel -o husky-kernel-dist

# GrapheneOS tangorpro (Pixel Tablet) kernel dist files
nix build -L .#grapheneos-tangorpro-kernel -o tangorpro-kernel-dist

# GrapheneOS mustang (Pixel 10 Pro XL) kernel dist files
nix build -L .#grapheneos-mustang-kernel -o mustang-kernel-dist
```

## ForkGram

Build the APK (unsigned):

```zsh
nix build .#apk_forkgram -o forkgram
# APK at forkgram/forkgram.apk
```

### Generate a signing key

```zsh
keytool -genkeypair -v \
  -keystore my-release-key.jks \
  -alias releasekey -keyalg RSA -keysize 4096 -validity 10000 \
  -storepass password \
  -dname "CN=Your Name,O=Your Org,C=US"
```

> Note: modern JDKs create PKCS12 keystores which use the store password for
> the key as well — do not pass a separate `-keypass`.

### Re-sign the APK with your key

```zsh
nix run .#apk_forkgram.signScript -- \
  my-release-key.jks \
  --ks-pass password \
  --out forkgram-signed.apk
nix run -L .#apk_zotero-android.signScript -- \
  my-release-key.jks \
  --ks-pass password \
  --out zotero-signed.apk
NIXPKGS_ALLOW_UNFREE=1 nix run --impure .#apk_meshtastic.signScript -- \
  my-release-key.jks \
  --ks-pass password \
  --out meshtastic-signed.apk
```

If `--ks-pass` is omitted the script prompts interactively.

Verify the signature:

```zsh
apksigner verify --print-certs forkgram-signed.apk
```

### Build an unsigned F-Droid repo

```zsh
nix build .#fdroid-repo -o fdroid-repo
# Unsigned APK staging at fdroid-repo/unsigned
```

### Sign APKs and F-Droid repo with your key

```zsh
nix build .#sign-fdroid-repo -o sign-fdroid-repo
./sign-fdroid-repo/bin/sign-fdroid-repo my-release-key.jks \
  --ks-pass password \
  --alias releasekey \
  --out fdroid-repo-signed
```

Or with `nix run`:

```zsh
NIXPKGS_ALLOW_UNFREE=1 nix run --impure .#sign-fdroid-repo -- \
  my-release-key.jks \
  --ks-pass password \
  --alias releasekey \
  --out fdroid-repo-signed
```

Signed repo output is in `fdroid-repo-signed/repo`.

## update

use update-nix-fetchgit and nvfetcher

## todo

+ <https://github.com/nix-community/robotnix/commit/2b5be1b40170aff4a9841d291b2c3303e6e04154#commitcomment-181052651>

read

+ <https://xdaforums.com/t/improving-s-pen-sensitivity-under-lineage-roms.4752027/>
+ <https://github.com/osbm/nixapks>
+ <https://github.com/tiann/KernelSU/issues/2942#issuecomment-4078266560>
+ <https://www.reddit.com/r/LineageOS/comments/1oaw2hj/comment/nkisxra/>
