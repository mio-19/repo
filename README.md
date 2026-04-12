# repo

This repository contains build scripts for android applications and operating systems based on android.

Warning: This repository contains many llm generated glue code. They might be written on false assumptions but happen to work. Don't trust them. See later section LLM for more details.

This repository implemented a build system for gradle and maven to replace prebuilt jar with versions built with source code. Of couse the versions built with source code still have their own prebuilt dependencies jar. But now it is possible to gradually work towards the goal of fully building from source code. A problem is bootstrapping. For example gradle uses old gradle to build. Expect long build time when build cache is not available.

Warning: Using this repository may result in data loss, boot loops, bricked devices, injuries due to exploded devices, dead SD cards, thermonuclear war, lawsuit, banned account, money loss, or you getting fired because the alarm app failed. By proceeding, you accept full responsibility for any issues that may arise.

Warning: Note that using some of the build scripts from this repository might be disallowed by copyright/trademark holders. Although many projects are distributed with a free software license, building a project from source code to create a working binary  might be explicitly disallowed or a gray area even if the modification to the source code is just minimal building process related changes to be as close as possible with the prebuilt version. Let alone introducing patches to the projects. A project might explicitly demand icon change and logo change for modified versions. This repository is only available as source code only. The relavent source code of build script in this repository is never executed but only looked at. The relavent source code of build script is for demonstration purpose only, not for actually running. Please understand the responsibility if you decide to possibly break the law to execute the build script in this repository to recreate a binary from source code even when the only change to the source code of an android application is to make it build and as close as possible to the prebuilt versions.

Warning: Some nix files in this repository produce fully broken or mostly broken results.

I want the following freedom on my devices: `The freedom to study how the program works, and change it so it does your computing as you wish (freedom 1). Access to the source code is a precondition for this.` However it is always false on certain operating systems. Certain operating systems in principle discourage users from modifying any application.

[Android App Readme](./app)

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
nix build -L --max-jobs 4 .#los.enchilada_derpfest16.img -o enchilada-img.zip
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
nix build -L --max-jobs 4 .#gos.caiman.releaseScript -o release && ./release ./keys-caiman
nix build -L --max-jobs 4 .#gosNoCcache.caiman.releaseScript -o release && ./release ./keys-caiman
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
nix build -L .#gos.caiman.generateKeysScript -o generate-keys && ./generate-keys ./keys-caiman
nix build -L .#gosNoCcache.caiman.generateKeysScript -o generate-keys && ./generate-keys ./keys-caiman
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

## LLM

This repository contains many llm generated glue code. They might be written on false assumptions but happen to work. Don't trust them.

Glue code might be generated by llm. They are the kind of code that is good enough if they work. They are the kind of code that usually don't affect the final logic in any way. For example, it usually doesn't matter too much for the final result when packaging an android application with the correct way or an incorrect way of copying files around into deprecated folder structure that happen to work.

## Help Wanted

+ publish a pre-built repository for apk of distributable android applications in this repository

+ publish pre-built rom for this operating system based on grapheneos that is not grapheneos. modifications include kernelsu and pixel8 pro pwm mod.


## ForkGram and other android applications

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
  --out fdroid-repo-signed
```

Or with `nix run`:

```zsh
NIXPKGS_ALLOW_UNFREE=1 nix run --impure .#sign-fdroid-repo -- \
  my-release-key.jks \
  --ks-pass password \
  --out fdroid-repo-signed
```

Signed repo output is in `fdroid-repo-signed/repo`.

Alias behavior is automatic (no `--alias` flag):

- Default: each APK is signed with key alias = its appId/package name.
- Termux family apps that require the shared Termux signature (`com.termux`, `com.termux.styling`, `org.gnu.emacs`) use shared alias `com.termux`.
- Termux:X11 (`com.termux.x11`) uses its own `com.termux.x11` alias.
- `nix-on-droid` (`com.termux.nix`) keeps old alias `releasekey`.

### Add missing key aliases to an existing keystore

Use the helper script to create aliases for newly added APKs in the same keystore:

```zsh
nix run .#fdroid-keystore-update -- my-release-key.jks --ks-pass password --alias org.joinmastodon.android
nix run .#fdroid-keystore-update -- my-release-key.jks --ks-pass password --alias me.proton.android.lumo
```

You can pass multiple `--alias` flags.

If `--alias` is omitted, it auto-discovers APK package names from `.#fdroid-repo` and ensures all required aliases automatically using the same mapping as `sign-fdroid-repo`:

- `com.termux.nix` -> `releasekey`
- `com.termux`, `com.termux.styling`, `org.gnu.emacs` -> `com.termux`
- `com.termux.x11` -> `com.termux.x11`
- all others -> appId/package name

```zsh
nix run .#fdroid-keystore-update -- my-release-key.jks --ks-pass password
```

## update

use update-nix-fetchgit and nvfetcher

## lock

see <https://github.com/nix-community/robotnix/blob/a2c5626074199e6b990fdeb8107f43b73d0be17d/docs/src/installation.md?plain=1#L50>

```zsh
    $ fastboot erase avb_custom_key
    $ fastboot flash avb_custom_key ./avb_pkmd.bin
    $ fastboot reboot bootloader
```

## todo

read

+ <https://xdaforums.com/t/improving-s-pen-sensitivity-under-lineage-roms.4752027/>
+ <https://github.com/osbm/nixapks>
+ <https://github.com/tiann/KernelSU/issues/2942#issuecomment-4078266560>
+ <https://www.reddit.com/r/LineageOS/comments/1oaw2hj/comment/nkisxra/>
