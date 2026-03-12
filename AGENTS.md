# Repo Rules

- Do not manually edit generated source files such as `_sources/generated.nix` or `_sources/generated.json`.
- When source metadata needs to be refreshed, run `nix run nixpkgs#nvfetcher` from the repo root and let it update generated files.
