{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      sources = (import ../_sources/generated.nix) {
        inherit (pkgs)
          fetchurl
          fetchgit
          fetchFromGitHub
          dockerTools
          ;
      };

      # Generic helper: zipalign + apksigner wrapper for any pre-built APK.
      # Args:
      #   name       – script binary name (e.g. "sign-forkgram")
      #   apkPath    – store path to the unsigned APK (e.g. "${forkgram}/forkgram.apk")
      #   defaultOut – default output filename (e.g. "forkgram-signed.apk")
      mkSignScript =
        {
          name,
          apkPath,
          defaultOut,
        }:
        let
          androidSdk = inputs.android-nixpkgs.sdk.${system} (s: [
            s.cmdline-tools-latest
            s.build-tools-36-1-0
          ]);
        in
        pkgs.writeShellScriptBin name ''
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
          ${lib.getExe pkgs.apksigner} sign \
            --ks "$KEYSTORE" \
            --ks-pass "pass:$KS_PASS" \
            --key-pass "pass:$KEY_PASS" \
            --out "$OUT" \
            "$TMP"

          echo "Signed APK written to: $OUT"
        '';

      helperScope = {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        gradle2nixBuilders = inputs.gradle2nix.builders.${system};
        inherit
          mkSignScript
          sources
          ;
        apkeditor = pkgs.apkeditor;
        apktool-src = sources.morphe_apktool.src;
        multidexlib2-src = sources.morphe_multidexlib2.src;
      };

      apkScope = lib.makeScope pkgs.newScope (_: byName // helperScope);

      apk = lib.filesystem.packagesFromDirectoryRecursive {
        inherit (apkScope) callPackage newScope;
        directory = ./by-name-apk;
      };

      byNameScope = lib.makeScope pkgs.newScope (
        _:
        helperScope
        // {
          inherit apk;
        }
      );

      byName = lib.filesystem.packagesFromDirectoryRecursive {
        inherit (byNameScope)
          callPackage
          newScope
          ;
        directory = ./by-name;
      };
    in
    {
      packages = byName // lib.mapAttrs' (name: value: lib.nameValuePair ("apk_" + name) value) apk;
    };
}
