# Repo Rules

- Do not manually edit generated source files such as `_sources/generated.nix` or `_sources/generated.json`.
- When source metadata needs to be refreshed, run `nix run nixpkgs#nvfetcher` from the repo root and let it update generated files.
- Use `nurl`, or run `nix run nixpkgs#nurl <url to patch>`, to get a `fetchpatch` expression for patch URLs.
- Never use `sed -i` to patch source files in Nix derivations. Use `substituteInPlace --replace-fail` for single-line substitutions. For multi-line or structural changes, generate a proper patch with `diff -u` against the real upstream source file; never write patch hunks by hand.
- Never use `perl -i` / `perl -pe` or python source rewriting in Nix derivations; use `substituteInPlace --replace-fail` or a proper `diff -u` patch instead.
- Follow patterns of exisiting code
- Make sure `nix build` actually can build before declaring completing a task!
- Remember to `git add` when nix complaints about path does not exist!
- Remember no network in nix build environemnt expect for fixed output derviation!!
- Always set hash to fakeHash or empty or AAAAAA before needing to get new hash like changed fetch options updated tag rev!
- for `''` in nix, prefixing common spaces will be removed. please format nix files corectly that is bash heredoc within double quotes block in nix can have similar indentation as the rest of the file. if unsure run nixfmt on the file and check what did nixfmt do!
- if any group-index hash mismatch, update the hash (replace old hash with new hash) in all json deps files!