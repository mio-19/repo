# repo
android devices rom configurations

command examples:
```zsh
nix build .#android.gta4xlwifi23.ota



nix build .#androidSign.gta4xlwifi23.releaseScript
```

generate keys/updating keys:
```zsh
nix build .#android.gta4xlwifi23.generateKeysScript
./generate-keys ./keys
```


build kernels:
```zsh
nix build .#gta4xlwifi23
```