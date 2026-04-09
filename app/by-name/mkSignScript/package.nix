{
  androidSdkBuilder,
  writeShellScriptBin,
  lib,
  apksigner,
}:
# Generic helper: zipalign + apksigner wrapper for any pre-built APK.
# Args:
#   name       – script binary name (e.g. "sign-forkgram")
#   apkPath    – store path to the unsigned APK (e.g. "${forkgram}/forkgram.apk")
#   defaultOut – default output filename (e.g. "forkgram-signed.apk")

{
  name,
  apkPath,
  defaultOut,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.build-tools-36-1-0
  ]);
in
writeShellScriptBin name ''
  set -euo pipefail
  usage() {
    echo "Usage: ${name} <keystore> [--ks-pass <pass>] [--key-pass <pass>] [--out <output.apk>]"
    echo ""
    echo "Re-signs ${apkPath} with the given JKS/PKCS12 keystore."
    echo "Options:"
    echo "  --ks-pass   Keystore password (default: env KS_PASS, else prompts)"
    echo "  --key-pass  Key password (default: env KEY_PASS, else same as --ks-pass)"
    echo "  --out       Output APK path (default: ${defaultOut})"
    exit 1
  }

  KEYSTORE="''${1:?$(usage)}"
  shift

  KS_PASS="''${KS_PASS:-}"
  KEY_PASS="''${KEY_PASS:-}"
  OUT="${defaultOut}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ks-pass)  KS_PASS="$2";  shift 2 ;;
      --key-pass) KEY_PASS="$2"; shift 2 ;;
      --out)      OUT="$2";      shift 2 ;;
      *) echo "Unknown option: $1"; usage ;;
    esac
  done

  if [[ -z "$KS_PASS" ]]; then
    read -rsp "Keystore password: " KS_PASS; echo
  fi
  if [[ -z "$KEY_PASS" ]]; then
    KEY_PASS="$KS_PASS"
  fi

  TMP=$(mktemp "''${TMPDIR:-/tmp}/${name}.XXXXXX.apk")
  trap 'rm -f "$TMP"' EXIT

  echo "Aligning APK..."
  ${androidSdk}/share/android-sdk/build-tools/36.1.0/zipalign -f 4 \
    "${apkPath}" "$TMP"

  echo "Signing APK..."
  ${lib.getExe apksigner} sign \
    --ks "$KEYSTORE" \
    --ks-pass "pass:$KS_PASS" \
    --key-pass "pass:$KEY_PASS" \
    --out "$OUT" \
    "$TMP"

  echo "Signed APK written to: $OUT"
''
