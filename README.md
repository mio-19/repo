# repo
android devices rom configurations

command examples:
```zsh
nix build --max-jobs 4 .#los.gta4xlwifi23.ota

nix build --max-jobs 4 .#gos.akita.ota



nix build --max-jobs 4 .#losSign.gta4xlwifi23.releaseScript --impure -o release
./release ./keys



nix build --max-jobs 4 .#gosSign.akita.releaseScript --impure -o release
./release ./keys
```

generate keys/updating keys:
```zsh
nix build .#gos.akita.generateKeysScript -o generate-keys
./generate-keys ./keys
```


build kernels:
```zsh
nix build .#gta4xlwifi23
```

## update

use update-nix-fetchgit and nvfetcher