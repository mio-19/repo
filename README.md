# repo

android devices rom configurations

command examples:

```zsh
nix build --max-jobs 4 .#los.gta4xlwifi.ota -o gta4xlwifi.zip

nix build --max-jobs 4 .#los.enchilada.ota -o enchilada.zip

nix build --max-jobs 4 .#gos.akita.ota



nix build --max-jobs 4 .#losSign.gta4xlwifi.releaseScript --impure -o release
./release ./keys



nix build --max-jobs 4 .#gosSign.akita.releaseScript --impure -o release && ./release ./keys
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
