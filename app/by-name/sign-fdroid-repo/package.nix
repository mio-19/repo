{
  fdroid-repo,
  androidSdkBuilder,
  python3,
  dejavu_fonts,
  writeShellScriptBin,
  jdk,
  lib,
  fdroidserver,
}:
let
  # Generic helper: signs an unsigned F-Droid repo index using fdroidserver.
  # Args:
  #   name         – script binary name (e.g. "sign-fdroid-repo")
  #   repoPath     – store path to unsigned repo root containing unsigned/
  #   defaultOut   – default output directory
  #   defaultAlias – default key alias in keystore
  mkFdroidRepoSignScript =
    {
      name,
      repoPath,
      defaultOut,
      defaultAlias,
    }:
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.build-tools-36-0-0
      ]);
      iconPython = python3.withPackages (ps: [
        ps.cairosvg
        ps.pillow
      ]);
      iconFont = "${dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf";
    in
    writeShellScriptBin name ''
      set -euo pipefail
      usage() {
        echo "Usage: ${name} <keystore> [--ks-pass <pass>] [--key-pass <pass>] [--alias <keyalias>] [--out <output-dir>] [--repo-url <url>]"
        echo ""
        echo "Signs APKs from ${repoPath}/unsigned and builds a signed F-Droid repo."
        echo "Options:"
        echo "  --ks-pass   Keystore password (default: env KS_PASS, else prompts)"
        echo "  --key-pass  Key password (default: env KEY_PASS, else same as --ks-pass)"
        echo "  --alias     Key alias in keystore (default: ${defaultAlias})"
        echo "  --out       Output directory (default: ${defaultOut})"
        echo "  --repo-url  Final published repo URL written to repo metadata"
        exit 1
      }

      KEYSTORE="''${1:?$(usage)}"
      shift

      # Resolve before changing directories so relative paths work reliably.
      KEYSTORE="$(cd "$(dirname "$KEYSTORE")" && pwd)/$(basename "$KEYSTORE")"
      if [[ ! -f "$KEYSTORE" ]]; then
        echo "Keystore not found: $KEYSTORE" >&2
        exit 1
      fi

      KS_PASS="''${KS_PASS:-}"
      KEY_PASS="''${KEY_PASS:-}"
      ALIAS="${defaultAlias}"
      OUT="${defaultOut}"
      REPO_URL=""

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --ks-pass)  KS_PASS="$2";  shift 2 ;;
          --key-pass) KEY_PASS="$2"; shift 2 ;;
          --alias)    ALIAS="$2";    shift 2 ;;
          --out)      OUT="$2";      shift 2 ;;
          --repo-url) REPO_URL="$2"; shift 2 ;;
          *) echo "Unknown option: $1"; usage ;;
        esac
      done

      if [[ -z "$KS_PASS" ]]; then
        read -rsp "Keystore password: " KS_PASS; echo
      fi
      if [[ -z "$KEY_PASS" ]]; then
        KEY_PASS="$KS_PASS"
      fi

      WORKDIR=$(mktemp -d "''${TMPDIR:-/tmp}/${name}.XXXXXX")
      trap 'rm -rf "$WORKDIR"' EXIT

      cp -R "${repoPath}"/. "$WORKDIR"/
      chmod -R u+w "$WORKDIR"

      if [[ -f "$WORKDIR/config.yml" ]]; then
        tmp_config="$WORKDIR/config.yml.tmp"
        grep -Ev '^(repo_url|repo_keyalias|keystore|keystorepass|keypass|keydname|keyaliases):' \
          "$WORKDIR/config.yml" > "$tmp_config" || true
        mv "$tmp_config" "$WORKDIR/config.yml"
      fi

      if [[ ! -d "$WORKDIR/unsigned" ]]; then
        echo "Expected unsigned APK directory in ${repoPath}/unsigned" >&2
        exit 1
      fi

      shopt -s nullglob
      apk_files=("$WORKDIR"/unsigned/*.apk)
      shopt -u nullglob
      if [[ "''${#apk_files[@]}" -eq 0 ]]; then
        echo "No APK files found in $WORKDIR/unsigned" >&2
        exit 1
      fi

      keyaliases_yaml=""
      for apk in "''${apk_files[@]}"; do
        badging="$(${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt dump badging "$apk")"
        pkg="$(echo "$badging" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")"
        if [[ -z "$pkg" ]]; then
          echo "Failed to parse package name from $apk" >&2
          exit 1
        fi
        keyaliases_yaml+="  ''${pkg}: ''${ALIAS}"$'\n'
      done

      printf '%s\n' \
        "repo_keyalias: $ALIAS" \
        "keystore: $KEYSTORE" \
        "keystorepass: $KS_PASS" \
        "keypass: $KEY_PASS" \
        "keydname: CN=F-Droid Repo, OU=F-Droid" \
        "keyaliases:" \
        "$keyaliases_yaml" >> "$WORKDIR/config.yml"
      if [[ -n "$REPO_URL" ]]; then
        printf 'repo_url: %s\n' "$REPO_URL" >> "$WORKDIR/config.yml"
      fi
      chmod 600 "$WORKDIR/config.yml"

      export HOME="$WORKDIR/.home"
      mkdir -p "$HOME"

      # fdroidserver requires a JDK at runtime (java, keytool, jarsigner).
      export JAVA_HOME="${jdk}"
      export PATH="$JAVA_HOME/bin:$PATH"

      (cd "$WORKDIR" && ${lib.getExe fdroidserver} publish --error-on-failed)
      (cd "$WORKDIR" && ${lib.getExe fdroidserver} update --create-metadata --rename-apks --nosign)
      ${iconPython}/bin/python3 ${./fdroid-repo-icon-fallback.py} \
        "$WORKDIR" \
        "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt" \
        "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2" \
        "${iconFont}"
      (cd "$WORKDIR" && ${lib.getExe fdroidserver} signindex)

      rm -rf "$OUT"
      mkdir -p "$OUT"
      cp -R "$WORKDIR/repo" "$OUT/repo"
      if [[ -d "$WORKDIR/metadata" ]]; then
        cp -R "$WORKDIR/metadata" "$OUT/metadata"
      fi

      echo "Signed F-Droid repo written to: $OUT"
    '';
in
mkFdroidRepoSignScript {
  name = "sign-fdroid-repo";
  repoPath = "${fdroid-repo}";
  defaultOut = "fdroid-repo-signed";
  defaultAlias = "releasekey";
}
