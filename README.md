# repo

android devices rom configurations

command examples:

```zsh
nix build --max-jobs 4 .#los.gta4xlwifi.ota -o gta4xlwifi.zip

nix build --max-jobs 4 .#los.enchilada.ota -o enchilada.zip
nix build --max-jobs 4 .#los.enchilada.img -o enchilada-img.zip


nix build --max-jobs 4 .#gos.akita.ota



nix build --max-jobs 4 .#losSign.gta4xlwifi.releaseScript --impure -o release
./release ./keys-akita



nix build --max-jobs 4 .#gosSign.akita.releaseScript --impure -o release && ./release ./keys-akita
nix build --max-jobs 4 .#gosSign.husky.releaseScript --impure -o release && ./release ./keys-husky
```

generate keys/updating keys:

```zsh
nix build .#gos.akita.generateKeysScript -o generate-keys
./generate-keys ./keys-akita

nix build .#gos.husky.generateKeysScript -o generate-keys
./generate-keys ./keys-husky

nix build .#losSign.gta4xlwifi.generateKeysScript -o generate-keys
./generate-keys ./keys-akita
```

build kernels:

```zsh
nix build .#gta4xlwifi -o gta4xlwifi
```

## update

use update-nix-fetchgit and nvfetcher

## husky kernel

+ <https://grapheneos.org/build#prebuilt-code>
+ <https://github.com/updateing/android_kernel_google_zuma/commits/14.0.0-sultan-pwm/>
+ <https://xdaforums.com/t/a-mod-on-pwm-frequency-v3-20241027.4683727/>
+ <https://xdaforums.com/t/a-mod-on-pwm-frequency-v3-20241027.4683727/page-8#post-89915781>

FROM 98034a90a743131b9542b5d580fe46c8be69296a
TO   60d772c2e51304d1454be922afd4eba02b5c50ca

```
git fetch https://github.com/updateing/android_kernel_google_zuma.git 14.0.0-sultan-pwm
```

adjusted patch from sultan branch: pixel8pro-14.0.0-sultan-pwm.patch

adjusted patch with  Stock-based variant: pixel8pro-stock.patch with kernel crash fix: pixel8pro-stock-fix.patch

adjusted patch from <https://github.com/elephant-43/kernel_google-modules_display_samsung> <https://github.com/elephant-43/kernel_devices_google_shusky> pixel8pro-elephant-43.patch with kernel crash fix: pixel8pro-elephant-43-fix.patch

adjusted patch from <https://github.com/elephant-43/kernel_google-modules_display> <https://github.com/elephant-43/kernel_devices_google_shusky> pixel8pro-elephant-43-b.patch (not that different from pixel8pro-elephant-43.patch) TODO: correct this patch

```zsh
sudo apt install libssl-dev
KLEAF_REPO_MANIFEST=aosp_manifest.xml ./build_shusky.sh --lto=full

```
