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
