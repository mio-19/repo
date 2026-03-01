# repo

android devices rom configurations

command examples:

```zsh
nix build -L --max-jobs 4 .#los.gta4xlwifi.ota -o gta4xlwifi.zip

nix build -L --max-jobs 4 .#los.enchilada.ota -o enchilada.zip
nix build -L --max-jobs 4 .#los.enchilada.img -o enchilada-img.zip


nix build -L --max-jobs 4 .#gos.akita.ota



nix build -L --max-jobs 4 .#losSign.gta4xlwifi.releaseScript --impure -o release
./release ./keys-akita



nix build -L --max-jobs 4 .#gosSign.akita.releaseScript --impure -o release && ./release ./keys-akita
nix build -L --max-jobs 4 .#gosSign.husky.releaseScript --impure -o release && ./release ./keys-husky
```

generate keys/updating keys:

```zsh
nix build -L .#gos.akita.generateKeysScript -o generate-keys
./generate-keys ./keys-akita

nix build -L .#gos.husky.generateKeysScript -o generate-keys
./generate-keys ./keys-husky

nix build -L .#losSign.gta4xlwifi.generateKeysScript -o generate-keys
./generate-keys ./keys-akita
```

build kernels:

```zsh
nix build -L .#gta4xlwifi -o gta4xlwifi

# GrapheneOS husky (Pixel 8 Pro) kernel dist files
nix build -L .#grapheneos-husky-kernel -o husky-kernel-dist
```

## update

use update-nix-fetchgit and nvfetcher
