# koreader-wip

use gits.py in koreader repo to get repos.nix

```zsh
git clone --recurse-submodules https://github.com/koreader/koreader.git
cd koreader
git checkout v2026.07.2
git submodule update --init --recursive
nix shell nixpkgs#nurl -c python3 ../gits.py . > ../repos.nix
nixfmt ../repos.nix
```
