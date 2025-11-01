# repo
android devices rom configurations

command examples:
```zsh
nix build .#los.gta4xlwifi23.ota

nix build .#gos.akita.ota



nix build .#losSign.gta4xlwifi23.releaseScript --impure -o release
./release ./keys



nix build .#gosSign.akita.releaseScript --impure -o release
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