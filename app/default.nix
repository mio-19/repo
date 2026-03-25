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
            s.build-tools-36-0-0
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
          ${androidSdk}/share/android-sdk/build-tools/36.0.0/zipalign -f 4 \
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
          androidSdk = inputs.android-nixpkgs.sdk.${system} (s: [
            s.cmdline-tools-latest
            s.build-tools-36-0-0
          ]);
          iconPython = pkgs.python3.withPackages (ps: [
            ps.cairosvg
            ps.pillow
          ]);
          iconFont = "${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf";
        in
        pkgs.writeShellScriptBin name ''
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
          export JAVA_HOME="${pkgs.jdk}"
          export PATH="$JAVA_HOME/bin:$PATH"

          (cd "$WORKDIR" && ${lib.getExe pkgs.fdroidserver} publish --error-on-failed)
          (cd "$WORKDIR" && ${lib.getExe pkgs.fdroidserver} update --create-metadata --rename-apks --nosign)
          ${iconPython}/bin/python3 ${./fdroid-repo-icon-fallback.py} \
            "$WORKDIR" \
            "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt" \
            "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2" \
            "${iconFont}"
          (cd "$WORKDIR" && ${lib.getExe pkgs.fdroidserver} signindex)

          rm -rf "$OUT"
          mkdir -p "$OUT"
          cp -R "$WORKDIR/repo" "$OUT/repo"
          if [[ -d "$WORKDIR/metadata" ]]; then
            cp -R "$WORKDIR/metadata" "$OUT/metadata"
          fi

          echo "Signed F-Droid repo written to: $OUT"
        '';

      forkgram = pkgs.callPackage ./forkgram {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        gradle2nixBuilders = inputs.gradle2nix.builders.${system};
      };

      meshtastic = pkgs.callPackage ./meshtastic {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      droidspaces-oss = pkgs.callPackage ./droidspaces-oss {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      microg-re = pkgs.callPackage ./microg-re {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      youtubeMorphe = pkgs.callPackage ./youtube {
        inherit morphe-cli morphe-patches;
      };

      youtubeMusicMorphe = pkgs.callPackage ./youtube-music {
        inherit morphe-cli morphe-patches;
      };

      redditMorphe = pkgs.callPackage ./reddit {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        apkeditor = pkgs.apkeditor;
        inherit morphe-cli morphe-patches;
      };

      spotifyRevanced = pkgs.callPackage ./spotify {
        apkeditor = pkgs.apkeditor;
        inherit revanced-cli revanced-patches;
      };

      duolingoRevanced = pkgs.callPackage ./duolingo {
        apkeditor = pkgs.apkeditor;
        inherit revanced-cli revanced-patches;
      };

      microsoftLensRevanced = pkgs.callPackage ./microsoft-lens {
        inherit revanced-cli revanced-patches;
      };

      facebookRevanced = pkgs.callPackage ./facebook {
        inherit revanced-cli revanced-patches;
      };

      instagramRevanced = pkgs.callPackage ./instagram {
        inherit apkeditor revanced-cli revanced-patches;
      };

      biliroaming = pkgs.callPackage ./biliroaming {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      bilibiliRoaming = pkgs.callPackage ./bilibili {
        apkeditor = pkgs.apkeditor;
        lspatchCli = lspatch-cli;
        biliroaming = biliroaming;
      };

      thunderbird = pkgs.callPackage ./thunderbird {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      emacs = pkgs.callPackage ./emacs {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      lspatch = pkgs.callPackage ./lspatch {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      lspatch-cli = lspatch.cli;
      lspatch-manager = lspatch.manager;

      nix-on-droid = pkgs.callPackage ./nix-on-droid {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      tailscale = pkgs.callPackage ./tailscale {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      termux = pkgs.callPackage ./termux {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      termux-styling = pkgs.callPackage ./termux-styling {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      termuxX11 = pkgs.callPackage ./termux-x11 {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      kernelsu = pkgs.callPackage ./kernelsu {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      gadgetbridge = pkgs.callPackage ./gadgetbridge {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      meditrak = pkgs.callPackage ./meditrak {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      zotero-android = pkgs.callPackage ./zotero-android {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      tuxguitar = pkgs.callPackage ./tuxguitar {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      meshcore-open = pkgs.callPackage ./meshcore-open {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      element-android = pkgs.callPackage ./element-android {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      appstore = pkgs.callPackage ./appstore {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        src = sources.grapheneos_appstore.src;
        version = sources.grapheneos_appstore.version;
      };

      shizuku = pkgs.callPackage ./shizuku {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      glimpse = pkgs.callPackage ./glimpse {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        src = sources.lineage_glimpse.src;
        version = sources.lineage_glimpse.version;
      };

      sunup = pkgs.callPackage ./sunup {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      recorder = pkgs.callPackage ./recorder {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        src = sources.lineage_recorder.src;
        version = sources.lineage_recorder.version;
      };

      haven = pkgs.callPackage ./haven {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      gamenative = pkgs.callPackage ./gamenative {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      vpnhotspot = pkgs.callPackage ./vpnhotspot {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      archivetune = pkgs.callPackage ./archivetune {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      amethyst = pkgs.callPackage ./amethyst {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      koreader = pkgs.callPackage ./koreader {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      morphe-library-m2 = pkgs.callPackage ./morphe-cli/morphe-library-m2.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      morphe-patches-gradle-plugin = pkgs.callPackage ./morphe-cli/morphe-patches-gradle-plugin.nix { };
      morphe-cli = pkgs.callPackage ./morphe-cli/default.nix {
        inherit morphe-library-m2;
        apktool-src = sources.morphe_apktool.src;
        multidexlib2-src = sources.morphe_multidexlib2.src;
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      morphe-patches = pkgs.callPackage ./morphe-cli/morphe-patches.nix {
        inherit morphe-patches-gradle-plugin morphe-library-m2;
        python3 = pkgs.python3;
        apktool-src = sources.morphe_apktool.src;
        multidexlib2-src = sources.morphe_multidexlib2.src;
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      revanced-jadb-m2 = pkgs.callPackage ./revanced-cli/revanced-jadb-m2.nix { };
      revanced-apktool-m2 = pkgs.callPackage ./revanced-cli/revanced-apktool-m2.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      revanced-multidexlib2-m2 = pkgs.callPackage ./revanced-cli/revanced-multidexlib2-m2.nix { };
      revanced-patcher-m2 = pkgs.callPackage ./revanced-cli/revanced-patcher-m2.nix {
        inherit revanced-apktool-m2 revanced-multidexlib2-m2;
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      revanced-library-m2 = pkgs.callPackage ./revanced-cli/revanced-library-m2.nix {
        inherit revanced-jadb-m2 revanced-patcher-m2;
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      revanced-patches-gradle-plugin =
        pkgs.callPackage ./revanced-cli/revanced-patches-gradle-plugin.nix
          { };
      revanced-patches = pkgs.callPackage ./revanced-cli/revanced-patches.nix {
        inherit revanced-patches-gradle-plugin revanced-patcher-m2;
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      revanced-cli = pkgs.callPackage ./revanced-cli/default.nix {
        inherit revanced-library-m2 revanced-patcher-m2;
      };
      apkeditor = pkgs.apkeditor;
      fdroid-basic = pkgs.callPackage ./fdroid-basic {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      fdroidRepo = pkgs.callPackage ./fdroid-repo.nix {
        androidSdk = inputs.android-nixpkgs.sdk.${system} (s: [
          s.cmdline-tools-latest
          s.platform-tools
          s.platforms-android-36
          s.build-tools-36-0-0
        ]);
        apps = [
          {
            appId = "org.fdroid.basic";
            apkPath = "${fdroid-basic}/fdroid-basic.apk";
            metadataYml = ''
              Categories:
                - App Store & Updater
                - System
              License: GPL-3.0-or-later
              AuthorName: F-Droid
              AuthorEmail: team@f-droid.org
              WebSite: https://f-droid.org
              SourceCode: https://gitlab.com/fdroid/fdroidclient
              IssueTracker: https://gitlab.com/fdroid/fdroidclient/issues
              Translation: https://hosted.weblate.org/projects/f-droid/f-droid
              Changelog: https://gitlab.com/fdroid/fdroidclient/-/blob/HEAD/CHANGELOG.md
              Donate: https://f-droid.org/donate
              Liberapay: F-Droid-Data
              OpenCollective: F-Droid-Euro
              Bitcoin: bc1qd8few44yaxc3wv5ceeedhdszl238qkvu50rj4v
              AutoName: F-Droid Basic
              Summary: Basic F-Droid client
              Description: |-
                F-Droid Basic is a lightweight client for browsing and installing
                applications from F-Droid repositories.
                This package is built from source.
            '';
          }
          {
            appId = "moe.shizuku.privileged.api";
            apkPath = "${shizuku}/shizuku.apk";
            metadataYml = ''
              Categories:
                - System
              License: Apache-2.0
              SourceCode: https://github.com/rikkaapps/shizuku
              IssueTracker: https://github.com/rikkaapps/shizuku/issues
              AutoName: Shizuku
              Summary: Run privileged APIs via a user-service bridge
              Description: |-
                Shizuku provides a bridge to use system-level APIs from apps
                without requiring root for every operation.
                This package is built from source.
            '';
          }
          {
            appId = "app.grapheneos.apps";
            apkPath = "${appstore}/appstore.apk";
            metadataYml = ''
              Categories:
                - System
              License: Apache-2.0
              SourceCode: https://github.com/GrapheneOS/AppStore
              IssueTracker: https://github.com/GrapheneOS/AppStore/issues
              AutoName: GrapheneOS App Store
              Summary: App repository client for GrapheneOS apps
              Description: |-
                GrapheneOS App Store is the client for GrapheneOS app repositories.
                This package is built from source.
            '';
          }
          {
            appId = "com.droidspaces.app";
            apkPath = "${droidspaces-oss}/droidspaces-oss.apk";
            metadataYml = ''
              Categories:
                - System
              License: GPL-3.0-only
              SourceCode: https://github.com/ravindu644/Droidspaces-OSS
              IssueTracker: https://github.com/ravindu644/Droidspaces-OSS/issues
              AutoName: Droidspaces
              Summary: Containerized Linux workspace plus terminal for Android
              Description: |-
                Droidspaces launches pre-configured Linux containers, terminals,
                and utilities directly on Android. The build here matches upstream
                source artifacts.
            '';
          }
          {
            appId = "org.lineageos.glimpse";
            apkPath = "${glimpse}/glimpse.apk";
            metadataYml = ''
              Categories:
                - Photography
              License: Apache-2.0
              SourceCode: https://github.com/LineageOS/android_packages_apps_Glimpse
              IssueTracker: https://github.com/LineageOS/android_packages_apps_Glimpse/issues
              AutoName: Glimpse
              Summary: LineageOS Glimpse photo gallery
              Description: |-
                Glimpse is the default photo gallery app for LineageOS, built from source.
            '';
          }
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
          {
            appId = "com.geeksville.mesh";
            apkPath = "${meshtastic}/meshtastic.apk";
            metadataYml = ''
              Categories:
                - Internet
              License: GPL-3.0-only
              SourceCode: https://github.com/meshtastic/Meshtastic-Android
              IssueTracker: https://github.com/meshtastic/Meshtastic-Android/issues
              AutoName: Meshtastic
              Summary: Meshtastic mesh networking app
              Description: |-
                Meshtastic is an open-source, off-grid mesh networking application
                using LoRa radios. This is the F-Droid flavor built from source.
            '';
          }
          {
            appId = "app.revanced.android.gms";
            apkPath = "${microg-re}/microg-re.apk";
            metadataYml = ''
              Categories:
                - System
              License: Apache-2.0
              SourceCode: https://github.com/MorpheApp/MicroG-RE
              IssueTracker: https://github.com/MorpheApp/MicroG-RE/issues
              AutoName: MicroG RE
              Summary: microG fork for patched Google apps
              Description: |-
                MicroG RE is a fork of microG GmsCore adapted for patched Google
                apps and distributed under an alternative package name.
                This package is built from source.
            '';
          }
          {
            appId = "net.thunderbird.android";
            apkPath = "${thunderbird}/thunderbird.apk";
            metadataYml = ''
              Categories:
                - Internet
              License: Apache-2.0
              SourceCode: https://github.com/thunderbird/thunderbird-android
              IssueTracker: https://github.com/thunderbird/thunderbird-android/issues
              AutoName: Thunderbird
              Summary: Thunderbird for Android (foss flavor)
              Description: |-
                Thunderbird is a free, open-source email client. This is the F-Droid
                foss flavor built from the THUNDERBIRD_17_0 branch without any
                proprietary Google dependencies.
            '';
          }
          {
            appId = "org.lsposed.lspatch";
            apkPath = "${lspatch-manager}/lspatch-manager.apk";
            metadataYml = ''
              Categories:
                - Development
                - System
              License: GPL-3.0-only
              WebSite: https://github.com/JingMatrix/LSPatch
              SourceCode: https://github.com/JingMatrix/LSPatch
              IssueTracker: https://github.com/JingMatrix/LSPatch/issues
              AutoName: LSPatch
              Summary: Rootless LSPosed patch manager
              Description: |-
                LSPatch is a rootless implementation of the LSPosed framework.

                This package is the Android manager app built from source.
                The matching CLI jar is also packaged separately in this repo
                as `lspatch-cli`.
            '';
          }
          {
            appId = "be.mygod.vpnhotspot";
            apkPath = "${vpnhotspot}/vpnhotspot.apk";
            metadataYml = ''
              Categories:
                - Connectivity
                - VPN & Proxy
              License: Apache-2.0
              AuthorName: Mygod Studio
              AuthorEmail: contact-vpnhotspot@mygod.be
              WebSite: https://mygod.be/
              SourceCode: https://github.com/Mygod/VPNHotspot
              IssueTracker: https://github.com/Mygod/VPNHotspot/issues
              Changelog: https://github.com/Mygod/VPNHotspot/releases
              Donate: https://mygod.be/donate/
              AutoName: VPN Hotspot
              Summary: Share VPN connections over hotspot and tethering
              Description: |-
                VPN Hotspot helps share a VPN connection over Wi-Fi hotspot,
                USB tethering, Bluetooth tethering, and related Android
                networking paths.

                This package is built from source and follows the F-Droid
                packaging approach, with Google services removed for a fully
                libre build.
              RequiresRoot: true
            '';
          }
          {
            appId = "projects.medicationtracker";
            apkPath = "${meditrak}/meditrak.apk";
            metadataYml = ''
              Categories:
                - Health & Fitness
              License: GPL-3.0-only
              SourceCode: https://github.com/AdamGuidarini/MediTrak
              IssueTracker: https://github.com/AdamGuidarini/MediTrak/issues
              AutoName: MediTrak
              Summary: Medication tracker
              Description: |-
                MediTrak is a simple, offline medication tracking app.
                Track doses, set reminders, and view history — no account required.
            '';
          }
          {
            appId = "app.tuxguitar.android.application";
            apkPath = "${tuxguitar}/tuxguitar-android.apk";
            metadataYml = ''
              Categories:
                - Multimedia
              License: LGPL-2.1-or-later
              SourceCode: https://github.com/helge17/tuxguitar
              IssueTracker: https://github.com/helge17/tuxguitar/issues
              AutoName: TuxGuitar
              Summary: Multitrack guitar tablature editor
              Description: |-
                TuxGuitar is a multitrack guitar tablature editor and player.
                It can open GuitarPro, PowerTab, and TablEdit files.
            '';
          }
          {
            appId = "org.zotero.android";
            apkPath = "${zotero-android}/zotero-android.apk";
            metadataYml = ''
              Categories:
                - Reading
                - Science & Education
              License: AGPL-3.0-only
              WebSite: https://www.zotero.org/
              SourceCode: https://github.com/zotero/zotero-android
              IssueTracker: https://github.com/zotero/zotero-android/issues
              Changelog: https://github.com/zotero/zotero-android/releases
              AutoName: Zotero
              Summary: Sync and manage your Zotero library on Android
              Description: |-
                Zotero is a research assistant for collecting, organizing,
                annotating, and syncing references, PDFs, and notes.

                This package is built from source from the latest upstream tag.
            '';
          }
          {
            appId = "com.meshcore.meshcore_open";
            apkPath = "${meshcore-open}/meshcore-open.apk";
            metadataYml = ''
              Categories:
                - Internet
              License: MIT
              SourceCode: https://github.com/zjs81/meshcore-open
              IssueTracker: https://github.com/zjs81/meshcore-open/issues
              AutoName: MeshCore Open
              Summary: Mesh networking client for MeshCore devices
              Description: |-
                MeshCore Open is an open-source client for MeshCore LoRa mesh
                networking devices, supporting messaging, channels, maps, and
                device management.
            '';
          }
          {
            appId = "im.vector.app";
            apkPath = "${element-android}/element-android.apk";
            metadataYml = ''
              Categories:
                - Internet
              License: Apache-2.0
              SourceCode: https://github.com/element-hq/element-android
              IssueTracker: https://github.com/element-hq/element-android/issues
              AutoName: Element
              Summary: Secure Matrix messenger (F-Droid flavor)
              Description: |-
                Element is a Matrix-based end-to-end encrypted messenger and
                collaboration app. This is the F-Droid flavor built from source
                without proprietary Google services.
            '';
          }
          {
            appId = "org.unifiedpush.distributor.sunup";
            apkPath = "${sunup}/sunup.apk";
            metadataYml = ''
              Categories:
                - System
              License: GPL-3.0-or-later
              SourceCode: https://codeberg.org/Sunup/android
              IssueTracker: https://codeberg.org/Sunup/android/issues
              AutoName: Sunup
              Summary: UnifiedPush distributor using a local push gateway
              Description: |-
                Sunup is a UnifiedPush distributor that uses a local push gateway
                to deliver push notifications without relying on Google services.
                This package is built from source.
            '';
          }
          {
            appId = "app.gamenative";
            apkPath = "${gamenative}/gamenative.apk";
            metadataYml = ''
              Categories:
                - Games
              License: GPL-3.0-only
              SourceCode: https://github.com/utkarshdalal/GameNative
              IssueTracker: https://github.com/utkarshdalal/GameNative/issues
              Changelog: https://github.com/utkarshdalal/GameNative/releases
              AutoName: GameNative
              Summary: Android launcher for running Windows games
              Description: |-
                GameNative is an Android launcher for running Windows games with
                integrated container, Steam, and compatibility-layer management.
                This package is built from source.
            '';
          }
          {
            appId = "moe.koiverse.archivetune";
            apkPath = "${archivetune}/archivetune.apk";
            metadataYml = ''
              AntiFeatures:
                NonFreeNet:
                  en-US: Depends on YouTube and YouTube Music.
              Categories:
                - Multimedia
              License: GPL-3.0-only
              SourceCode: https://github.com/koiverse/ArchiveTune
              IssueTracker: https://github.com/koiverse/ArchiveTune/issues
              AutoName: ArchiveTune
              Summary: Privacy-focused YouTube Music client
              Description: |-
                ArchiveTune is a YouTube Music client for Android with offline-friendly
                source packaging, modern Material 3 UI, lyrics support, and playback
                customization features.
                This package is built from source.
            '';
          }
          {
            appId = "org.angelauramc.amethyst";
            apkPath = "${amethyst}/amethyst.apk";
            metadataYml = ''
              Categories:
                - Games
              License: GPL-3.0-only
              SourceCode: https://github.com/AngelAuraMC/Amethyst-Android
              IssueTracker: https://github.com/AngelAuraMC/Amethyst-Android/issues
              Changelog: https://github.com/AngelAuraMC/Amethyst-Android/commits/v3_openjdk
              AutoName: Amethyst
              Summary: Android launcher for Minecraft Java Edition
              Description: |-
                Amethyst is an Android launcher for Minecraft Java Edition based
                on the PojavLauncher codebase with an updated native stack and
                bundled runtime components.
                This package is built from source from the latest `v3_openjdk`
                branch commit pinned in this repo.
            '';
          }
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
          {
            appId = "com.tailscale.ipn";
            apkPath = "${tailscale}/tailscale.apk";
            metadataYml = ''
              Categories:
                - Internet
              License: BSD-3-Clause
              WebSite: https://tailscale.com/
              SourceCode: https://github.com/tailscale/tailscale-android
              IssueTracker: https://github.com/tailscale/tailscale-android/issues
              Changelog: https://github.com/tailscale/tailscale-android/releases
              AutoName: Tailscale
              Summary: Mesh VPN client
              Description: |-
                Tailscale is a mesh VPN client for connecting devices over a
                private WireGuard-based network.
                This package is built from source from the upstream
                tailscale-android repository.
            '';
          }
          {
            appId = "com.termux";
            apkPath = "${termux}/termux.apk";
            metadataYml = ''
              Categories:
                - Development
              License: GPL-3.0-only
              WebSite: https://termux.com
              SourceCode: https://github.com/termux/termux-app
              IssueTracker: https://github.com/termux/termux-app/issues
              Changelog: https://github.com/termux/termux-app/releases
              Donate: https://termux.com/donate.html
              OpenCollective: Termux
              AutoName: Termux
              Summary: Terminal emulator with Linux packages
              Description: |-
                Termux combines terminal emulation with a Linux package collection.
                This package is built from source from the upstream termux-app
                repository and follows the F-Droid universal APK build approach.
            '';
          }
          {
            appId = "com.termux.styling";
            apkPath = "${termux-styling}/termux-styling.apk";
            metadataYml = ''
              Categories:
                - Development
              License: GPL-3.0-only
              WebSite: https://termux.com
              SourceCode: https://github.com/termux/termux-styling
              IssueTracker: https://github.com/termux/termux-styling/issues
              Changelog: https://github.com/termux/termux-styling/releases
              Donate: https://termux.com/donate.html
              OpenCollective: Termux
              AutoName: Termux:Styling
              Summary: Color schemes and fonts for Termux
              Description: |-
                This Termux plugin provides color schemes and powerline-ready fonts
                to customize the terminal appearance.
                This package is built from source from the upstream
                termux-styling GitHub repository at the latest commit after the
                0.32.1 F-Droid release.
            '';
          }
          {
            appId = "com.termux.x11";
            apkPath = "${termuxX11}/termux-x11.apk";
            metadataYml = ''
              Categories:
                - Development
              License: GPL-3.0-only
              WebSite: https://termux.com
              SourceCode: https://github.com/termux/termux-x11
              IssueTracker: https://github.com/termux/termux-x11/issues
              Changelog: https://github.com/termux/termux-x11/releases/tag/nightly
              Donate: https://termux.com/donate.html
              OpenCollective: Termux
              AutoName: Termux:X11
              Summary: X11 server add-on for Termux
              Description: |-
                Termux:X11 is the X11 server companion app for Termux.
                This package is built from source from the upstream master
                branch at commit 3376f0ed5f5c7cf4ba960df218a00c6cc053ffb7.

                F-Droid does not currently ship metadata for this application,
                so this repo follows the upstream nightly debug universal APK
                build layout instead.
            '';
          }
          {
            appId = "org.gnu.emacs";
            apkPath = "${emacs}/emacs.apk";
            metadataYml = ''
              Categories:
                - Development
                - Text Editor
                - Writing
              License: GPL-3.0-or-later
              WebSite: https://www.gnu.org/software/emacs/
              SourceCode: https://git.savannah.gnu.org/cgit/emacs.git/tree/
              IssueTracker: https://debbugs.gnu.org/
              Changelog: https://git.savannah.gnu.org/cgit/emacs.git/tree/etc/NEWS?h=master
              Donate: https://my.fsf.org/donate/
              AutoName: Emacs
              Summary: GNU Emacs with Termux shared user ID support
              Description: |-
                GNU Emacs is an extensible, customizable, free/libre text
                editor and Lisp environment.

                This build is compiled from source from the current Emacs 31.0.50
                development snapshot and configured with the shared user ID `com.termux`,
                so it can access the files and executables of the Termux app
                from this repo when both are installed and signed together.

                Install Termux first, then install this Emacs build.
            '';
          }
          # need different gradle lockfile on darwin
          {
            appId = "sh.haven.app";
            apkPath = "${haven}/haven.apk";
            metadataYml = ''
              Categories:
                - Internet
                - System
              License: GPL-3.0-only
              SourceCode: https://github.com/GlassOnTin/Haven
              IssueTracker: https://github.com/GlassOnTin/Haven/issues
              AutoName: Haven
              Summary: SSH/Mosh terminal and Reticulum network client
              Description: |-
                Haven is an SSH/Mosh terminal and Reticulum network client for Android,
                featuring end-to-end encrypted messaging via the Reticulum stack.
                This package is built from source (arm64).
            '';
          }
          # on darwin:  error: bitwise operation between different enumeration types ('ecma_property_flags_t' and 'ecma_property_types_t') [-Werror,-Wenum-enum-conversion]
          {
            appId = "nodomain.freeyourgadget.gadgetbridge";
            apkPath = "${gadgetbridge}/gadgetbridge.apk";
            metadataYml = ''
              Categories:
                - Connectivity
                - Health & Fitness
              License: Apache-2.0
              WebSite: https://gadgetbridge.org/
              SourceCode: https://codeberg.org/Freeyourgadget/Gadgetbridge
              IssueTracker: https://codeberg.org/Freeyourgadget/Gadgetbridge/issues
              Changelog: https://codeberg.org/Freeyourgadget/Gadgetbridge/releases
              AutoName: Gadgetbridge
              Summary: Companion app for wearable devices
              Description: |-
                Gadgetbridge is a libre companion app for wearable devices.

                This package is built from source and follows the current
                F-Droid mainline build, including the Fossil HR asset build step.
            '';
          }
          # [CXX1429] error when building with ndkBuild using /nix/var/nix/builds/nix-38269-3239929316/source/termux-shared/src/main/cpp/Android.mk: ERROR: Unknown host CPU architecture: arm64
          {
            appId = "com.termux.nix";
            apkPath = "${nix-on-droid}/nix-on-droid.apk";
            metadataYml = ''
              Categories:
                - Development
              License: MIT
              WebSite: https://nix-on-droid.unboiled.info
              SourceCode: https://github.com/nix-community/nix-on-droid
              IssueTracker: https://github.com/nix-community/nix-on-droid/issues
              Name: Nix-on-Droid
              AutoName: Nix
              Description: |-
                Nix-on-Droid brings the Nix package manager to Android.

                This app is the terminal-emulator part, built from the
                `nix-on-droid-app` source repository that F-Droid uses for
                the `com.termux.nix` package.

                Nix-on-Droid uses a fork of the Termux application as its
                terminal emulator.
            '';
          }
          # ndk from nixpkgs: error: Android NDK doesn't support building on arm64-apple-darwin, as far as we know
          # actually ndk from android-nixpkgs run fine on aarch64 darwin with rosetta2 with x86_64 ndk.
          # ndk failed to build on x86_64 linud after recent nixpkgs bump. last working: 9cf7092bdd603554bd8b63c216e8943cf9b12512 first broken: 4724d5647207377bede08da3212f809cbd94a648
          /*
            {
              appId = "me.weishu.kernelsu";
              apkPath = "${kernelsu}/kernelsu.apk";
              metadataYml = ''
                Categories:
                  - System
                License: GPL-3.0-or-later
                WebSite: https://kernelsu.org/
                SourceCode: https://github.com/tiann/KernelSU
                IssueTracker: https://github.com/tiann/KernelSU/issues
                Changelog: https://github.com/tiann/KernelSU/releases
                AutoName: KernelSU
                Summary: Kernel-based root manager
                Description: |-
                  KernelSU is a kernel-based root solution for Android with a
                  companion manager app for granting root access, managing modules,
                  and configuring policies.

                  This package is the upstream manager app built from source.
                RequiresRoot: true
              '';
            }
          */
          # cannot build on darwin due to stdenv
          {
            appId = "org.koreader.launcher.fdroid";
            apkPath = "${koreader}/koreader.apk";
            metadataYml = ''
              Categories:
                - Reading
              License: AGPL-3.0-only
              SourceCode: https://github.com/koreader/koreader
              IssueTracker: https://github.com/koreader/koreader/issues
              AutoName: KOReader
              Summary: Ebook reader optimized for e-ink and Android devices
              Description: |-
                KOReader is a document reader supporting EPUB, PDF, DJVU and more.
                This package is built from source.
            '';
          }
          # can build locally but not on garnix
          {
            appId = "org.lineageos.recorder";
            apkPath = "${recorder}/recorder.apk";
            metadataYml = ''
              Categories:
                - Multimedia
              License: Apache-2.0
              SourceCode: https://github.com/LineageOS/android_packages_apps_Recorder
              IssueTracker: https://github.com/LineageOS/android_packages_apps_Recorder/issues
              AutoName: Recorder
              Summary: LineageOS screen and audio recorder
              Description: |-
                Recorder is the LineageOS app for recording audio and screen.
                This package is built from source.
            '';
          }
          # gradle lock platform dependent issue. need update lock for darwin:
          {
            appId = "app.morphe.android.youtube";
            apkPath = "${youtubeMorphe}/youtube-morphe.apk";
            metadataYml = ''
              Categories:
                - Multimedia
              License: Proprietary
              SourceCode: https://github.com/MorpheApp/morphe-patches
              IssueTracker: https://github.com/MorpheApp/morphe-patches/issues
              AutoName: YouTube Morphe
              Summary: Patched YouTube APK with package rename
              Description: |-
                YouTube Morphe is a patched YouTube APK built with Morphe patches
                and installed under an alternate package name.
            '';
          }
          {
            appId = "app.morphe.android.apps.youtube.music";
            apkPath = "${youtubeMusicMorphe}/youtube-music-morphe.apk";
            metadataYml = ''
              Categories:
                - Multimedia
              License: Proprietary
              SourceCode: https://github.com/MorpheApp/morphe-patches
              IssueTracker: https://github.com/MorpheApp/morphe-patches/issues
              AutoName: YouTube Music Morphe
              Summary: Patched YouTube Music APK with package rename
              Description: |-
                YouTube Music Morphe is a patched YouTube Music APK built with
                Morphe patches and installed under an alternate package name.
            '';
          }
          {
            appId = "com.reddit.frontpage.morphe";
            apkPath = "${redditMorphe}/reddit-morphe.apk";
            metadataYml = ''
              Categories:
                - Internet
              License: Proprietary
              SourceCode: https://github.com/MorpheApp/morphe-patches
              IssueTracker: https://github.com/MorpheApp/morphe-patches/issues
              AutoName: Reddit Morphe
              Summary: Patched Reddit APK with package rename
              Description: |-
                Reddit Morphe is a patched Reddit APK built with Morphe patches
                and installed under an alternate package name.
            '';
          }
          {
            appId = "com.spotify.music";
            apkPath = "${spotifyRevanced}/spotify-revanced.apk";
            metadataYml = ''
              Categories:
                - Multimedia
              License: Proprietary
              SourceCode: https://github.com/ReVanced/revanced-patches
              IssueTracker: https://github.com/ReVanced/revanced-patches/issues
              AutoName: Spotify ReVanced
              Summary: Patched Spotify APK
              Description: |-
                Spotify ReVanced is a patched Spotify APK built with ReVanced
                patches and kept under the original package name.
            '';
          }
          {
            appId = "com.duolingo";
            apkPath = "${duolingoRevanced}/duolingo-revanced.apk";
            metadataYml = ''
              Categories:
                - Internet
              License: Proprietary
              SourceCode: https://github.com/ReVanced/revanced-patches
              IssueTracker: https://github.com/ReVanced/revanced-patches/issues
              AutoName: Duolingo ReVanced
              Summary: Patched Duolingo APK
              Description: |-
                Duolingo ReVanced is a patched Duolingo APK built with ReVanced
                patches and kept under the original package name.
            '';
          }
          {
            appId = "com.microsoft.office.officelens";
            apkPath = "${microsoftLensRevanced}/microsoft-lens-revanced.apk";
            metadataYml = ''
              Categories:
                - Productivity
              License: Proprietary
              SourceCode: https://github.com/ReVanced/revanced-patches
              IssueTracker: https://github.com/ReVanced/revanced-patches/issues
              AutoName: Microsoft Lens ReVanced
              Summary: Patched Microsoft Lens APK
              Description: |-
                Microsoft Lens ReVanced is a patched Microsoft Lens APK built
                with ReVanced patches and kept under the original package name.
            '';
          }
          {
            appId = "com.facebook.katana";
            apkPath = "${facebookRevanced}/facebook-revanced.apk";
            metadataYml = ''
              Categories:
                - Internet
              License: Proprietary
              SourceCode: https://github.com/ReVanced/revanced-patches
              IssueTracker: https://github.com/ReVanced/revanced-patches/issues
              AutoName: Facebook ReVanced
              Summary: Patched Facebook APK
              Description: |-
                Facebook ReVanced is a patched Facebook APK built with
                ReVanced patches and kept under the original package name.
            '';
          }
          {
            appId = "com.bilibili.app.in";
            apkPath = "${bilibiliRoaming}/bilibili-roaming.apk";
            metadataYml = ''
              Categories:
                - Video Players & Editors
              License: Proprietary
              SourceCode: https://github.com/yujincheng08/BiliRoaming
              IssueTracker: https://github.com/yujincheng08/BiliRoaming/issues
              AutoName: BiliBili Roaming
              Summary: BiliBili patched with BiliRoaming via LSPatch
              Description: |-
                BiliBili Roaming embeds the latest BiliRoaming Xposed module
                using LSPatch so the official BiliBili client bypasses region
                locks and gains other enhancements without root.
            '';
          }
          {
            appId = "com.instagram.android";
            apkPath = "${instagramRevanced}/instagram-revanced.apk";
            metadataYml = ''
              Categories:
                - Internet
              License: Proprietary
              SourceCode: https://github.com/ReVanced/revanced-patches
              IssueTracker: https://github.com/ReVanced/revanced-patches/issues
              AutoName: Instagram ReVanced
              Summary: Patched Instagram APK
              Description: |-
                Instagram ReVanced is a patched Instagram APK built with
                ReVanced patches and kept under the original package name.
            '';
          }
        ];
      };
    in
    {
      packages.forkgram = forkgram.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-forkgram";
          apkPath = "${forkgram}/forkgram.apk";
          defaultOut = "forkgram-signed.apk";
        };

        passthru.fdroidRepo = fdroidRepo;

        passthru.signFdroidRepoScript = mkFdroidRepoSignScript {
          name = "sign-fdroid-repo";
          repoPath = "${fdroidRepo}";
          defaultOut = "fdroid-repo-signed";
          defaultAlias = "releasekey";
        };
      });

      packages.meshtastic = meshtastic.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-meshtastic";
          apkPath = "${meshtastic}/meshtastic.apk";
          defaultOut = "meshtastic-signed.apk";
        };
      });

      packages.droidspaces-oss = droidspaces-oss.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-droidspaces-oss";
          apkPath = "${droidspaces-oss}/droidspaces-oss.apk";
          defaultOut = "droidspaces-oss-signed.apk";
        };
      });

      packages.microg-re = microg-re.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-microg-re";
          apkPath = "${microg-re}/microg-re.apk";
          defaultOut = "microg-re-signed.apk";
        };
      });

      packages.youtube-morphe = youtubeMorphe.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-youtube-morphe";
          apkPath = "${youtubeMorphe}/youtube-morphe.apk";
          defaultOut = "youtube-morphe-signed.apk";
        };
      });

      packages.youtube-music-morphe = youtubeMusicMorphe.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-youtube-music-morphe";
          apkPath = "${youtubeMusicMorphe}/youtube-music-morphe.apk";
          defaultOut = "youtube-music-morphe-signed.apk";
        };
      });

      packages.reddit-morphe = redditMorphe.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-reddit-morphe";
          apkPath = "${redditMorphe}/reddit-morphe.apk";
          defaultOut = "reddit-morphe-signed.apk";
        };
      });

      packages.spotify-revanced = spotifyRevanced.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-spotify-revanced";
          apkPath = "${spotifyRevanced}/spotify-revanced.apk";
          defaultOut = "spotify-revanced-signed.apk";
        };
      });

      packages.duolingo-revanced = duolingoRevanced.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-duolingo-revanced";
          apkPath = "${duolingoRevanced}/duolingo-revanced.apk";
          defaultOut = "duolingo-revanced-signed.apk";
        };
      });

      packages.microsoft-lens-revanced = microsoftLensRevanced.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-microsoft-lens-revanced";
          apkPath = "${microsoftLensRevanced}/microsoft-lens-revanced.apk";
          defaultOut = "microsoft-lens-revanced-signed.apk";
        };
      });

      packages.facebook-revanced = facebookRevanced.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-facebook-revanced";
          apkPath = "${facebookRevanced}/facebook-revanced.apk";
          defaultOut = "facebook-revanced-signed.apk";
        };
      });

      packages.biliroaming = biliroaming;

      packages.bilibili-roaming = bilibiliRoaming.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-bilibili-roaming";
          apkPath = "${bilibiliRoaming}/bilibili-roaming.apk";
          defaultOut = "bilibili-roaming-signed.apk";
        };
      });

      packages.instagram-revanced = instagramRevanced.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-instagram-revanced";
          apkPath = "${instagramRevanced}/instagram-revanced.apk";
          defaultOut = "instagram-revanced-signed.apk";
        };
      });

      packages.thunderbird = thunderbird.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-thunderbird";
          apkPath = "${thunderbird}/thunderbird.apk";
          defaultOut = "thunderbird-signed.apk";
        };
      });

      packages.emacs = emacs.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-emacs";
          apkPath = "${emacs}/emacs.apk";
          defaultOut = "emacs-signed.apk";
        };
      });

      packages.lspatch-cli = lspatch-cli;

      packages.lspatch-manager = lspatch-manager.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-lspatch-manager";
          apkPath = "${lspatch-manager}/lspatch-manager.apk";
          defaultOut = "lspatch-manager-signed.apk";
        };
      });

      packages.nix-on-droid = nix-on-droid.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-nix-on-droid";
          apkPath = "${nix-on-droid}/nix-on-droid.apk";
          defaultOut = "nix-on-droid-signed.apk";
        };
      });

      packages.tailscale = tailscale.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-tailscale";
          apkPath = "${tailscale}/tailscale.apk";
          defaultOut = "tailscale-signed.apk";
        };
      });

      packages.termux = termux.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-termux";
          apkPath = "${termux}/termux.apk";
          defaultOut = "termux-signed.apk";
        };
      });

      packages.termux-styling = termux-styling.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-termux-styling";
          apkPath = "${termux-styling}/termux-styling.apk";
          defaultOut = "termux-styling-signed.apk";
        };
      });

      packages.termux-x11 = termuxX11.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-termux-x11";
          apkPath = "${termuxX11}/termux-x11.apk";
          defaultOut = "termux-x11-signed.apk";
        };
      });

      packages.kernelsu = kernelsu.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-kernelsu";
          apkPath = "${kernelsu}/kernelsu.apk";
          defaultOut = "kernelsu-signed.apk";
        };
      });

      packages.gadgetbridge = gadgetbridge.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-gadgetbridge";
          apkPath = "${gadgetbridge}/gadgetbridge.apk";
          defaultOut = "gadgetbridge-signed.apk";
        };
      });

      packages.vpnhotspot = vpnhotspot.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-vpnhotspot";
          apkPath = "${vpnhotspot}/vpnhotspot.apk";
          defaultOut = "vpnhotspot-signed.apk";
        };
      });

      packages.meditrak = meditrak.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-meditrak";
          apkPath = "${meditrak}/meditrak.apk";
          defaultOut = "meditrak-signed.apk";
        };
      });

      packages.zotero-android = zotero-android.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-zotero-android";
          apkPath = "${zotero-android}/zotero-android.apk";
          defaultOut = "zotero-android-signed.apk";
        };
      });

      packages.tuxguitar-android = tuxguitar.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-tuxguitar-android";
          apkPath = "${tuxguitar}/tuxguitar-android.apk";
          defaultOut = "tuxguitar-android-signed.apk";
        };
      });

      packages.meshcore-open = meshcore-open.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-meshcore-open";
          apkPath = "${meshcore-open}/meshcore-open.apk";
          defaultOut = "meshcore-open-signed.apk";
        };
      });

      packages.element-android = element-android.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-element-android";
          apkPath = "${element-android}/element-android.apk";
          defaultOut = "element-android-signed.apk";
        };
      });
      packages.glimpse = glimpse.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-glimpse";
          apkPath = "${glimpse}/glimpse.apk";
          defaultOut = "glimpse-signed.apk";
        };
      });

      packages.sunup = sunup.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-sunup";
          apkPath = "${sunup}/sunup.apk";
          defaultOut = "sunup-signed.apk";
        };
      });

      packages.recorder = recorder.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-recorder";
          apkPath = "${recorder}/recorder.apk";
          defaultOut = "recorder-signed.apk";
        };
      });

      packages.haven = haven.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-haven";
          apkPath = "${haven}/haven.apk";
          defaultOut = "haven-signed.apk";
        };
      });

      packages.archivetune = archivetune.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-archivetune";
          apkPath = "${archivetune}/archivetune.apk";
          defaultOut = "archivetune-signed.apk";
        };
      });
      packages.amethyst = amethyst.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-amethyst";
          apkPath = "${amethyst}/amethyst.apk";
          defaultOut = "amethyst-signed.apk";
        };
      });

      packages.appstore = appstore.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-appstore";
          apkPath = "${appstore}/appstore.apk";
          defaultOut = "appstore-signed.apk";
        };
      });

      packages.shizuku = shizuku.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-shizuku";
          apkPath = "${shizuku}/shizuku.apk";
          defaultOut = "shizuku-signed.apk";
        };
      });

      packages.koreader = koreader.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-koreader";
          apkPath = "${koreader}/koreader.apk";
          defaultOut = "koreader-signed.apk";
        };
      });
      packages.gamenative = gamenative.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-gamenative";
          apkPath = "${gamenative}/gamenative.apk";
          defaultOut = "gamenative-signed.apk";
        };
      });
      packages.morphe-library-m2 = morphe-library-m2;
      packages.morphe-patches-gradle-plugin = morphe-patches-gradle-plugin;
      packages.morphe-cli = morphe-cli;
      packages.morphe-patches = morphe-patches;
      packages.revanced-jadb-m2 = revanced-jadb-m2;
      packages.revanced-apktool-m2 = revanced-apktool-m2;
      packages.revanced-multidexlib2-m2 = revanced-multidexlib2-m2;
      packages.revanced-patcher-m2 = revanced-patcher-m2;
      packages.revanced-library-m2 = revanced-library-m2;
      packages.revanced-patches-gradle-plugin = revanced-patches-gradle-plugin;
      packages.revanced-patches = revanced-patches;
      packages.revanced-cli = revanced-cli;

      packages.fdroid-basic = fdroid-basic.overrideAttrs (_: {
        passthru.signScript = mkSignScript {
          name = "sign-fdroid-basic";
          apkPath = "${fdroid-basic}/fdroid-basic.apk";
          defaultOut = "fdroid-basic-signed.apk";
        };
      });

      packages.fdroid-repo = fdroidRepo;

      packages.sign-fdroid-repo = mkFdroidRepoSignScript {
        name = "sign-fdroid-repo";
        repoPath = "${fdroidRepo}";
        defaultOut = "fdroid-repo-signed";
        defaultAlias = "releasekey";
      };
    };
}
