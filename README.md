# repo

android devices rom configurations

command examples:

```zsh
nix build --max-jobs 4 .#los.gta4xlwifi.ota -o gta4xlwifi.zip

nix build --max-jobs 4 .#los.enchilada.ota -o enchilada.zip
nix build --max-jobs 4 .#los.enchilada.img -o enchilada-img.zip


nix build --max-jobs 4 .#gos.akita.ota



nix build --max-jobs 4 .#losSign.gta4xlwifi.releaseScript --impure -o release
./release ./keys



nix build --max-jobs 4 .#gosSign.akita.releaseScript --impure -o release && ./release ./keys
nix build --max-jobs 4 .#gosSign.husky.releaseScript --impure -o release && ./release ./keys
```

generate keys/updating keys:

```zsh
nix build .#gos.akita.generateKeysScript -o generate-keys
./generate-keys ./keys


nix build .#losSign.gta4xlwifi.generateKeysScript -o generate-keys
./generate-keys ./keys
```

build kernels:

```zsh
nix build .#gta4xlwifi -o gta4xlwifi
```

## update

use update-nix-fetchgit and nvfetcher

## husky kernel

<https://grapheneos.org/build#prebuilt-code>

<https://github.com/updateing/android_kernel_google_zuma/commits/14.0.0-sultan-pwm/>

FROM 98034a90a743131b9542b5d580fe46c8be69296a
TO   60d772c2e51304d1454be922afd4eba02b5c50ca

```
git fetch https://github.com/updateing/android_kernel_google_zuma.git 14.0.0-sultan-pwm
```

adjusted patch: pixel8pro.patch


```zsh
rm -f private/devices/google/shusky/display/exynos_drm_decon.h
cp private/google-modules/display/samsung/exynos_drm_decon.h private/devices/google/shusky/display/
KLEAF_REPO_MANIFEST=aosp_manifest.xml ./build_shusky.sh --lto=full

```
