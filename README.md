# repo
android devices rom configurations

build commands:

```zsh
nix build .#android.enchilada22.ota --option extra-sandbox-paths /keys=$(pwd)/key
```