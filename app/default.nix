{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      androidSdk = inputs.android-nixpkgs.sdk.${system} (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.build-tools-35-0-0
        s.ndk-21-4-7075529
      ]);
      forkgram = pkgs.callPackage ./forkgram {
        inherit androidSdk;
        gradle2nixBuilders = inputs.gradle2nix.builders.${system};
      };
      signScript = pkgs.writeShellScriptBin "sign-forkgram" ''
        set -euo pipefail
        usage() {
          echo "Usage: sign-forkgram <keystore> [--ks-pass <pass>] [--key-pass <pass>] [--out <output.apk>]"
          echo ""
          echo "Re-signs the pre-built ForkGram APK with the given JKS/PKCS12 keystore."
          echo "Options:"
          echo "  --ks-pass   Keystore password (default: env KS_PASS, else prompts)"
          echo "  --key-pass  Key password (default: env KEY_PASS, else same as --ks-pass)"
          echo "  --out       Output APK path (default: forkgram-signed.apk)"
          exit 1
        }

        KEYSTORE="''${1:?$(usage)}"
        shift

        KS_PASS="''${KS_PASS:-}"
        KEY_PASS="''${KEY_PASS:-}"
        OUT="forkgram-signed.apk"

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

        TMP=$(mktemp --suffix=.apk)
        trap 'rm -f "$TMP"' EXIT

        echo "Aligning APK..."
        ${androidSdk}/share/android-sdk/build-tools/35.0.0/zipalign -f 4 \
          "${forkgram}/forkgram.apk" "$TMP"

        echo "Signing APK..."
        ${androidSdk}/share/android-sdk/build-tools/35.0.0/apksigner sign \
          --ks "$KEYSTORE" \
          --ks-pass "pass:$KS_PASS" \
          --key-pass "pass:$KEY_PASS" \
          --out "$OUT" \
          "$TMP"

        echo "Signed APK written to: $OUT"
      '';
    in
    {
      packages.forkgram = forkgram.overrideAttrs (_: {
        passthru.signScript = signScript;
      });
    };
}
