# repo

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
```

It is recommended to have OEM unlocking to be on in developer options when flashing new versions.

generate keys/updating keys:

```zsh
nix build -L .#gos.akita.generateKeysScript -o generate-keys && ./generate-keys ./keys-akita

nix build -L .#gos.husky.generateKeysScript -o generate-keys && ./generate-keys ./keys-husky

nix build -L .#gos.tangorpro.generateKeysScript -o generate-keys && ./generate-keys ./keys-tangorpro

nix build -L .#gos.mustang.generateKeysScript -o generate-keys && ./generate-keys ./keys-mustang

nix build -L .#los.gta4xlwifi.generateKeysScript -o generate-keys && ./generate-keys ./keys-akita
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
nix build .#forkgram -o forkgram
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
nix build .#forkgram.signScript -o sign-forkgram
./sign-forkgram/bin/sign-forkgram my-release-key.jks \
  --ks-pass password \
  --out forkgram-signed.apk
```

Or with `nix run`:

```zsh
nix run .#forkgram.signScript -- \
  my-release-key.jks \
  --ks-pass password \
  --out forkgram-signed.apk
```

If `--ks-pass` is omitted the script prompts interactively.

Verify the signature:

```zsh
apksigner verify --print-certs forkgram-signed.apk
```

## update

use update-nix-fetchgit and nvfetcher

## todo

read <https://xdaforums.com/t/improving-s-pen-sensitivity-under-lineage-roms.4752027/>
