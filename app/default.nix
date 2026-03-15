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
          ${androidSdk}/share/android-sdk/build-tools/35.0.0/zipalign -f 4 \
            "${apkPath}" "$TMP"

          echo "Signing APK..."
          ${androidSdk}/share/android-sdk/build-tools/35.0.0/apksigner sign \
            --ks "$KEYSTORE" \
            --ks-pass "pass:$KS_PASS" \
            --key-pass "pass:$KEY_PASS" \
            --out "$OUT" \
            "$TMP"

          echo "Signed APK written to: $OUT"
        '';

      # Generic helper: signs an unsigned F-Droid repo index using fdroidserver.
      # Args:
      #   name         – script binary name (e.g. "sign-fdroid-repo")
      #   repoPath     – store path to unsigned repo root containing repo/
      #   defaultOut   – default output directory
      #   defaultAlias – default key alias in keystore
      mkFdroidRepoSignScript =
        {
          name,
          repoPath,
          defaultOut,
          defaultAlias,
        }:
        pkgs.writeShellScriptBin name ''
          set -euo pipefail
          usage() {
            echo "Usage: ${name} <keystore> [--ks-pass <pass>] [--key-pass <pass>] [--alias <keyalias>] [--out <output-dir>]"
            echo ""
            echo "Signs F-Droid index files from ${repoPath}/repo using fdroidserver."
            echo "Options:"
            echo "  --ks-pass   Keystore password (default: env KS_PASS, else prompts)"
            echo "  --key-pass  Key password (default: env KEY_PASS, else same as --ks-pass)"
            echo "  --alias     Key alias in keystore (default: ${defaultAlias})"
            echo "  --out       Output directory (default: ${defaultOut})"
            exit 1
          }

          KEYSTORE="''${1:?$(usage)}"
          shift

          KS_PASS="''${KS_PASS:-}"
          KEY_PASS="''${KEY_PASS:-}"
          ALIAS="${defaultAlias}"
          OUT="${defaultOut}"

          while [[ $# -gt 0 ]]; do
            case "$1" in
              --ks-pass)  KS_PASS="$2";  shift 2 ;;
              --key-pass) KEY_PASS="$2"; shift 2 ;;
              --alias)    ALIAS="$2";    shift 2 ;;
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

          WORKDIR=$(mktemp -d "''${TMPDIR:-/tmp}/${name}.XXXXXX")
          trap 'rm -rf "$WORKDIR"' EXIT

          cp -R "${repoPath}"/. "$WORKDIR"/
          chmod -R u+w "$WORKDIR"

          if [[ ! -d "$WORKDIR/repo" ]]; then
            echo "Expected unsigned repository in ${repoPath}/repo" >&2
            exit 1
          fi

          cat > "$WORKDIR/config.yml" << EOF
          repo_keyalias: $ALIAS
          keystore: $KEYSTORE
          keystorepass: $KS_PASS
          keypass: $KEY_PASS
          EOF
          chmod 600 "$WORKDIR/config.yml"

          export HOME="$WORKDIR/.home"
          mkdir -p "$HOME"

          (cd "$WORKDIR" && ${pkgs.fdroidserver}/bin/fdroid signindex)

          rm -rf "$OUT"
          mkdir -p "$OUT"
          cp -R "$WORKDIR/repo" "$OUT/repo"
          if [[ -d "$WORKDIR/metadata" ]]; then
            cp -R "$WORKDIR/metadata" "$OUT/metadata"
          fi

          echo "Signed F-Droid repo written to: $OUT"
        '';

      forkgram = pkgs.callPackage ./forkgram {
        inherit androidSdk;
        gradle2nixBuilders = inputs.gradle2nix.builders.${system};
      };

      forkgramFdroidRepo = pkgs.callPackage ./fdroid-repo.nix {
        apps = [
          {
            appId = "org.forkgram.messenger";
            apkPath = "${forkgram}/forkgram.apk";
            metadataYml = ''
              Categories:
                - Internet
              License: GPL-2.0-or-later
              SourceCode: https://github.com/forkgram/TelegramAndroid
              IssueTracker: https://github.com/forkgram/TelegramAndroid/issues
              AutoName: Forkgram
              Summary: Telegram client fork
              Description: |-
                Forkgram is a Telegram Android client fork.
            '';
          }
        ];
        repoVersion = forkgram.version;
      };
    in
    {
      packages.forkgram = forkgram.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-forkgram";
          apkPath = "${forkgram}/forkgram.apk";
          defaultOut = "forkgram-signed.apk";
        };

        passthru.fdroidRepo = forkgramFdroidRepo;

        passthru.signFdroidRepoScript = mkFdroidRepoSignScript {
          name = "sign-fdroid-repo";
          repoPath = "${forkgramFdroidRepo}";
          defaultOut = "fdroid-repo-signed";
          defaultAlias = "releasekey";
        };
      });

      packages.fdroid-repo = forkgramFdroidRepo;

      packages.sign-fdroid-repo = mkFdroidRepoSignScript {
        name = "sign-fdroid-repo";
        repoPath = "${forkgramFdroidRepo}";
        defaultOut = "fdroid-repo-signed";
        defaultAlias = "releasekey";
      };
    };
}
