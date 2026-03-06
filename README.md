# repo

android devices rom configurations

command examples:

```zsh
nix build -L --max-jobs 4 .#los.gta4xlwifi.ota -o gta4xlwifi.zip
nix build -L --max-jobs 4 .#los.gts7lwifi.ota -o gts7lwifi.zip

nix build -L --max-jobs 4 .#los.enchilada.ota -o enchilada.zip
nix build -L --max-jobs 4 .#los.enchilada.img -o enchilada-img.zip
nix build -L --max-jobs 4 .#los.enchilada_mainline.img -o enchilada_mainline-img.zip

nix build -L --max-jobs 4 .#los.dm3q_cola2261.ota -o dm3q.zip

nix build -L --max-jobs 4 .#gos.akita.ota



nix build -L --max-jobs 4 .#los.gta4xlwifi.releaseScript -o release
./release ./keys-akita



nix build -L --max-jobs 4 .#gos.akita.releaseScript -o release && ./release ./keys-akita
nix build -L --max-jobs 4 .#gos.husky.releaseScript -o release && ./release ./keys-husky
```

It is recommended to have OEM unlocking to be on in developer options when flashing new versions.

generate keys/updating keys:

```zsh
nix build -L .#gos.akita.generateKeysScript -o generate-keys
./generate-keys ./keys-akita

nix build -L .#gos.husky.generateKeysScript -o generate-keys
./generate-keys ./keys-husky

nix build -L .#los.gta4xlwifi.generateKeysScript -o generate-keys
./generate-keys ./keys-akita
```

build kernels:

```zsh
nix build -L .#gta4xlwifi -o gta4xlwifi

nix build -L .#samsung_sm8250 -o samsung_sm8250

# GrapheneOS husky (Pixel 8 Pro) kernel dist files
nix build -L .#grapheneos-husky-kernel -o husky-kernel-dist
```

## update

use update-nix-fetchgit and nvfetcher
