# Repo Rules

- Do not manually edit generated source files such as `_sources/generated.nix` or `_sources/generated.json`.
- Do not manually edit generated Gradle MITM lockfiles such as `*_deps.json` / `immich_deps.json`; regenerate them only via the package's `mitmCache.updateScript`.
- When source metadata needs to be refreshed, run `nix run nixpkgs#nvfetcher` from the repo root and let it update generated files.
- Use `nurl`, or run `nix run nixpkgs#nurl <url to patch>`, to get a `fetchpatch` expression for patch URLs.
- Never use `sed -i` to patch source files in Nix derivations. Use `substituteInPlace --replace-fail` for single-line substitutions. For multi-line or structural changes, generate a proper patch with diff/git diff against the real upstream source file; never write patch hunks by hand.
- Never use `perl -i` / `perl -pe` or python source rewriting in Nix derivations; use `substituteInPlace --replace-fail` or a proper diff/git diff patch instead.
- Follow patterns of exisiting code, learn from exisiting working code and nixpkgs
- Make sure `nix build` actually can build before declaring completing a task!
- Remember to `git add` when nix complaints about path does not exist!
- Remember no network in nix build environemnt expect for fixed output derviation!!
- Always set hash to fakeHash or empty or AAAAAA before needing to get new hash like changed fetch options updated tag rev!
- for `''` in nix, prefixing common spaces will be removed. please format nix files corectly that is bash heredoc within double quotes block in nix can have similar indentation as the rest of the file. if unsure run nixfmt on the file and check what did nixfmt do!
- update mitm: `$(nix build .\#apk_tailscale.mitmCache.updateScript --no-link --print-out-paths)` note on nix: always use ./ instead of double quote string for data path! otherwise the outPath in mitmCache update script is not what we want. use `mitmCache = gradle.fetchDeps {  data = ./tailscale_deps.json;`; never use `data = "tailscale_deps.json";` It is common to see cleanup errors. Cleanup errors should not affect the main functionality of the mitmCache update script. Maybe need to put multiple tasks in gradleUpdateTask, seperated by space, if needed, when a specific task failed to build due to dependencies not in mitmCache
- fetchFromGitHub and fetching from git in nix: prefer tag over rev, use tag = "tag name" when fetching tag!
- DON"T EVER find grep or anything SEARCH ON EVERY FILES ON WHOLE nix store!!!! nix store is big and that takes forever.
- When working on patches. you try build for example gos.husky.config.source.dirs."path here".src to see if patch apply.
- we are using gradle2nix v2 <https://github.com/tadfisher/gradle2nix/pull/62>
