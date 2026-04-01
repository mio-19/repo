{
  writeShellScriptBin,
  jdk,
  fdroid-repo,
  androidSdkBuilder,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.build-tools-36-1-0
  ]);
in
writeShellScriptBin "fdroid-keystore-update" ''
  set -euo pipefail

  usage() {
    echo "Usage: fdroid-keystore-update <keystore> [--ks-pass <pass>] [--alias <appid|alias>]..."
    echo ""
    echo "Adds missing key aliases to an existing JKS/PKCS12 keystore."
    echo "By default, aliases are auto-discovered from ${fdroid-repo}/unsigned APKs."
    echo "Options:"
    echo "  --ks-pass  Keystore password (default: env KS_PASS, else prompts)"
    echo "  --alias    Alias to ensure exists (repeatable, disables auto-discovery)"
    echo ""
    echo "Auto alias mapping:"
    echo "  com.termux.nix -> releasekey"
    echo "  com.termux, com.termux.styling, com.termux.x11, org.gnu.emacs -> releasekey"
    echo "  otherwise -> appId/package name"
    exit 1
  }

  keyalias_for_pkg() {
    local pkg="$1"
    case "$pkg" in
      com.termux.nix) echo "releasekey" ;;
      com.termux|com.termux.styling|com.termux.x11|org.gnu.emacs) echo "releasekey" ;;
      *) echo "$pkg" ;;
    esac
  }

  KEYSTORE="''${1:?$(usage)}"
  shift

  KEYSTORE="$(cd "$(dirname "$KEYSTORE")" && pwd)/$(basename "$KEYSTORE")"
  if [[ ! -f "$KEYSTORE" ]]; then
    echo "Keystore not found: $KEYSTORE" >&2
    exit 1
  fi

  KS_PASS="''${KS_PASS:-}"
  declare -a aliases=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ks-pass) KS_PASS="$2"; shift 2 ;;
      --alias) aliases+=("$2"); shift 2 ;;
      *) echo "Unknown option: $1"; usage ;;
    esac
  done

  if [[ -z "$KS_PASS" ]]; then
    read -rsp "Keystore password: " KS_PASS
    echo
  fi

  if [[ "''${#aliases[@]}" -eq 0 ]]; then
    if [[ ! -d "${fdroid-repo}/unsigned" ]]; then
      echo "Expected unsigned APK directory in ${fdroid-repo}/unsigned" >&2
      exit 1
    fi
    shopt -s nullglob
    apk_files=("${fdroid-repo}"/unsigned/*.apk)
    shopt -u nullglob
    if [[ "''${#apk_files[@]}" -eq 0 ]]; then
      echo "No APK files found in ${fdroid-repo}/unsigned" >&2
      exit 1
    fi

    declare -A seen_aliases=()
    for apk in "''${apk_files[@]}"; do
      badging="$(${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt dump badging "$apk")"
      pkg="$(echo "$badging" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")"
      if [[ -z "$pkg" ]]; then
        echo "Failed to parse package name from $apk" >&2
        exit 1
      fi
      alias="$(keyalias_for_pkg "$pkg")"
      if [[ -z "''${seen_aliases[$alias]:-}" ]]; then
        aliases+=("$alias")
        seen_aliases["$alias"]=1
      fi
    done
  fi

  echo "Ensuring aliases: ''${aliases[*]}"

  for alias in "''${aliases[@]}"; do
    if ${jdk}/bin/keytool -list \
      -keystore "$KEYSTORE" \
      -storepass "$KS_PASS" \
      -alias "$alias" >/dev/null 2>&1; then
      echo "Alias exists: $alias"
      continue
    fi

    echo "Creating alias: $alias"
    ${jdk}/bin/keytool -genkeypair \
      -keystore "$KEYSTORE" \
      -storepass "$KS_PASS" \
      -alias "$alias" \
      -keyalg RSA \
      -keysize 4096 \
      -validity 10000 \
      -dname "CN=$alias,OU=F-Droid,O=F-Droid,C=US"
  done

  echo "Keystore update complete."
''
