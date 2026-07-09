# fdroid-repo-oss

TODO: This guide is from LLM. need to rewrite by human when time is available.

An F-Droid repository containing only apps that are built from open-source code and are probably safe to redistribute. This is a subset of the full [`fdroid-repo`](../fdroid-repo/package.nix).

## What is included

Apps are included when they:

- have F-Droid metadata (`metadataYml` and `appId`)
- open source
- are **not** on the explicit exclusion list (currently Telegram forks: `forkgram`, `forkgram-classic`)
- can be built on the current platform (same Linux-only exclusions as `fdroid-repo`)

## Build the unsigned repo

```zsh
nix build .#fdroid-repo-oss -o fdroid-repo-oss
```

Output layout:

- `fdroid-repo-oss/unsigned/` — APKs that need signing
- `fdroid-repo-oss/repo/` — pre-signed APKs (if any)
- `fdroid-repo-oss/metadata/` — per-app F-Droid metadata YAML
- `fdroid-repo-oss/config.yml` — repo config stub (unsigned)

## Create or update a signing keystore

Generate a new keystore (skip if you already have one):

```zsh
keytool -genkeypair \
  -keystore my-release-key.jks \
  -alias my-repo-key \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000 \
  -storepass password \
  -keypass password \
  -dname "CN=F-Droid Repo, OU=F-Droid, O=F-Droid, C=US"
```

Create one key alias per app package name. The helper discovers aliases from the unsigned APKs:

```zsh
nix run .#fdroid-keystore-update-oss -- my-release-key.jks --ks-pass password
```

Alias mapping (same as the full repo):

- `com.termux.nix` → `releasekey`
- `com.termux`, `com.termux.styling`, `org.gnu.emacs` → `com.termux`
- all others → appId / package name

You can also add aliases manually:

```zsh
nix run .#fdroid-keystore-update-oss -- my-release-key.jks \
  --ks-pass password \
  --alias org.joinmastodon.android
```

## Sign the repo

```zsh
nix build .#sign-fdroid-repo-oss -o sign-fdroid-repo-oss
./sign-fdroid-repo-oss/bin/sign-fdroid-repo-oss my-release-key.jks \
  --ks-pass password \
  --repo-url https://YOUR_USER.github.io/fdroid-repo-oss/repo \
  --out fdroid-repo-oss-signed
```

Or with `nix run`:

```zsh
NIXPKGS_ALLOW_UNFREE=1 nix run --impure .#sign-fdroid-repo-oss -- \
  my-release-key.jks \
  --ks-pass password \
  --repo-url https://YOUR_USER.github.io/fdroid-repo-oss/repo \
  --out fdroid-repo-oss-signed
```

Signed output is in `fdroid-repo-oss-signed/repo/`. Pass `--repo-url` with the URL where you will host the repo so F-Droid clients resolve APK links correctly.

Verify a signed APK:

```zsh
apksigner verify --print-certs fdroid-repo-oss-signed/repo/some-app.apk
```

## Host the repo

F-Droid clients need HTTPS access to the `repo/` directory. The simplest option is GitHub Pages.

### GitHub Pages

1. Create a repository (for example `fdroid-repo-oss`).
2. Copy the signed repo:

   ```zsh
   cp -R fdroid-repo-oss-signed/repo /path/to/fdroid-repo-oss/
   ```

3. Commit and push to the `main` branch.
4. Enable **Settings → Pages → Deploy from branch → main → / (root)**.
5. Your repo URL becomes `https://YOUR_USER.github.io/fdroid-repo-oss/repo`.

### Other static hosting

Upload `fdroid-repo-oss-signed/repo/` to any HTTPS static host (nginx, Caddy, S3 + CloudFront, etc.). The directory must contain at least:

- `index.html` (or `index-v1.json` for newer clients)
- `entry.jar`
- APK files referenced by the index

Set `--repo-url` during signing to match the public URL, for example `https://example.com/fdroid/repo`.

### Add the repo in F-Droid

1. Open F-Droid → **Settings** → **Repositories**.
2. Tap **+** and enter your repo URL (the `repo` path, e.g. `https://YOUR_USER.github.io/fdroid-repo-oss/repo`).
3. Scan the QR code on another device, or share the URL directly.

## Updating

After adding or updating OSS apps in this repository:

```zsh
nix build .#fdroid-repo-oss -o fdroid-repo-oss
nix run .#fdroid-keystore-update-oss -- my-release-key.jks --ks-pass password
./sign-fdroid-repo-oss/bin/sign-fdroid-repo-oss my-release-key.jks \
  --ks-pass password \
  --repo-url https://YOUR_USER.github.io/fdroid-repo-oss/repo \
  --out fdroid-repo-oss-signed
```

Then re-upload `fdroid-repo-oss-signed/repo/` to your host.

## Adding apps to this repo

1. Ensure the app package has `fdroid = { appId = ...; metadataYml = ...; }` via `mk-apk-package`.
2. Set `License:` in `metadataYml` to a free software license (not `Proprietary`).
3. If the app is a trademark derivative or otherwise not safe to redistribute despite the license, add its attr name to `nonOssApkNames` in [`../fdroid-repo/common.nix`](../fdroid-repo/common.nix).
