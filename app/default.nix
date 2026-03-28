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

      meshtastic = pkgs.callPackage ./by-name-apk/meshtastic/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      droidspaces-oss = pkgs.callPackage ./by-name-apk/droidspaces-oss/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      microg-re = pkgs.callPackage ./by-name-apk/microg-re/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      youtubeMorphe = pkgs.callPackage ./by-name-apk/youtube-morphe/package.nix {
        inherit morphe-cli morphe-patches;
      };

      youtubeMusicMorphe = pkgs.callPackage ./by-name-apk/youtube-music-morphe/package.nix {
        inherit morphe-cli morphe-patches;
      };

      redditMorphe = pkgs.callPackage ./by-name-apk/reddit-morphe/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        apkeditor = pkgs.apkeditor;
        inherit morphe-cli morphe-patches;
      };

      spotifyRevanced = pkgs.callPackage ./by-name-apk/spotify-revanced/package.nix {
        apkeditor = pkgs.apkeditor;
        inherit revanced-cli revanced-patches;
      };

      duolingoRevanced = pkgs.callPackage ./by-name-apk/duolingo-revanced/package.nix {
        apkeditor = pkgs.apkeditor;
        inherit revanced-cli revanced-patches;
      };

      microsoftLensRevanced = pkgs.callPackage ./by-name-apk/microsoft-lens-revanced/package.nix {
        inherit revanced-cli revanced-patches;
      };

      facebookRevanced = pkgs.callPackage ./by-name-apk/facebook-revanced/package.nix {
        inherit revanced-cli revanced-patches;
      };

      instagramRevanced = pkgs.callPackage ./by-name-apk/instagram-revanced/package.nix {
        inherit apkeditor revanced-cli revanced-patches;
      };

      immich = pkgs.callPackage ./by-name-apk/immich/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      biliroaming = pkgs.callPackage ./by-name/biliroaming/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      bilibiliPlay = pkgs.callPackage ./by-name-apk/bilibili-play/package.nix {
        lspatchCli = lspatch-cli;
        biliroaming = biliroaming;
      };

      bilibiliCn = pkgs.callPackage ./by-name-apk/bilibili-cn/package.nix {
        lspatchCli = lspatch-cli;
        biliroaming = biliroaming;
      };

      rednote = pkgs.callPackage ./by-name-apk/rednote/package.nix {
        lspatchCli = lspatch-cli;
      };

      thunderbird = pkgs.callPackage ./by-name-apk/thunderbird/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      emacs = pkgs.callPackage ./by-name-apk/emacs/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      lspatch-cli = pkgs.callPackage ./by-name/lspatch-cli/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      lspatch-manager = pkgs.callPackage ./by-name-apk/lspatch-manager/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      nix-on-droid = pkgs.callPackage ./by-name-apk/nix-on-droid/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      tailscale = pkgs.callPackage ./by-name-apk/tailscale/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      termux = pkgs.callPackage ./by-name-apk/termux/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      termux-styling = pkgs.callPackage ./by-name-apk/termux-styling/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      termuxX11 = pkgs.callPackage ./by-name-apk/termux-x11/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      kernelsu = pkgs.callPackage ./by-name-apk/kernelsu/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      gadgetbridge = pkgs.callPackage ./by-name-apk/gadgetbridge/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      meditrak = pkgs.callPackage ./by-name-apk/meditrak/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      zotero-android = pkgs.callPackage ./by-name-apk/zotero-android/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      tuxguitar = pkgs.callPackage ./by-name-apk/tuxguitar-android/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      meshcore-open = pkgs.callPackage ./by-name-apk/meshcore-open/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      element-android = pkgs.callPackage ./by-name-apk/element-android/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      appstore = pkgs.callPackage ./by-name-apk/appstore/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        src = sources.grapheneos_appstore.src;
        version = sources.grapheneos_appstore.version;
      };

      shizuku = pkgs.callPackage ./by-name-apk/shizuku/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      glimpse = pkgs.callPackage ./by-name-apk/glimpse/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        src = sources.lineage_glimpse.src;
        version = sources.lineage_glimpse.version;
      };

      sunup = pkgs.callPackage ./by-name-apk/sunup/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      recorder = pkgs.callPackage ./by-name-apk/recorder/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        src = sources.lineage_recorder.src;
        version = sources.lineage_recorder.version;
      };

      haven = pkgs.callPackage ./by-name-apk/haven/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      gamenative = pkgs.callPackage ./by-name-apk/gamenative/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      vpnhotspot = pkgs.callPackage ./by-name-apk/vpnhotspot/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      archivetune = pkgs.callPackage ./by-name-apk/archivetune/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      amethyst = pkgs.callPackage ./by-name-apk/amethyst/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      koreader = pkgs.callPackage ./by-name-apk/koreader/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      morphe-library-m2 = pkgs.callPackage ./by-name/morphe-library-m2/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      morphe-patches-gradle-plugin =
        pkgs.callPackage ./by-name/morphe-patches-gradle-plugin/package.nix
          { };
      morphe-cli = pkgs.callPackage ./by-name/morphe-cli/package.nix {
        inherit morphe-library-m2;
        apktool-src = sources.morphe_apktool.src;
        multidexlib2-src = sources.morphe_multidexlib2.src;
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      morphe-patches = pkgs.callPackage ./by-name/morphe-patches/package.nix {
        inherit morphe-patches-gradle-plugin morphe-library-m2;
        apktool-src = sources.morphe_apktool.src;
        multidexlib2-src = sources.morphe_multidexlib2.src;
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      revanced-jadb-m2 = pkgs.callPackage ./by-name/revanced-jadb-m2/package.nix { };
      revanced-apktool-m2 = pkgs.callPackage ./by-name/revanced-apktool-m2/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      revanced-multidexlib2-m2 = pkgs.callPackage ./by-name/revanced-multidexlib2-m2/package.nix { };
      revanced-patcher-m2 = pkgs.callPackage ./by-name/revanced-patcher-m2/package.nix {
        inherit revanced-apktool-m2 revanced-multidexlib2-m2;
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      revanced-library-m2 = pkgs.callPackage ./by-name/revanced-library-m2/package.nix {
        inherit revanced-jadb-m2 revanced-patcher-m2;
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      revanced-patches-gradle-plugin =
        pkgs.callPackage ./by-name/revanced-patches-gradle-plugin/package.nix
          { };
      revanced-patches = pkgs.callPackage ./by-name/revanced-patches/package.nix {
        inherit revanced-patches-gradle-plugin revanced-patcher-m2;
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };
      revanced-cli = pkgs.callPackage ./by-name/revanced-cli/package.nix {
        inherit revanced-library-m2 revanced-patcher-m2;
      };
      apkeditor = pkgs.apkeditor;
      fdroid-basic = pkgs.callPackage ./by-name-apk/fdroid-basic/package.nix {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      scope1 = {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        gradle2nixBuilders = inputs.gradle2nix.builders.${system};
        inherit mkSignScript;

        meshtastic = meshtastic;
        droidspaces-oss = droidspaces-oss;
        microg-re = microg-re;
        youtube-morphe = youtubeMorphe;
        youtube-music-morphe = youtubeMusicMorphe;
        rednote = rednote;
        reddit-morphe = redditMorphe;
        spotify-revanced = spotifyRevanced;
        duolingo-revanced = duolingoRevanced;
        microsoft-lens-revanced = microsoftLensRevanced;
        facebook-revanced = facebookRevanced;
        immich = immich;
        biliroaming = biliroaming;
        bilibili-play = bilibiliPlay;
        bilibili-cn = bilibiliCn;
        instagram-revanced = instagramRevanced;
        thunderbird = thunderbird;
        emacs = emacs;
        lspatch-cli = lspatch-cli;
        lspatch-manager = lspatch-manager;
        nix-on-droid = nix-on-droid;
        tailscale = tailscale;
        termux = termux;
        termux-styling = termux-styling;
        termux-x11 = termuxX11;
        kernelsu = kernelsu;
        gadgetbridge = gadgetbridge;
        vpnhotspot = vpnhotspot;
        meditrak = meditrak;
        zotero-android = zotero-android;
        tuxguitar-android = tuxguitar;
        meshcore-open = meshcore-open;
        element-android = element-android;
        glimpse = glimpse;
        sunup = sunup;
        recorder = recorder;
        haven = haven;
        archivetune = archivetune;
        amethyst = amethyst;
        appstore = appstore;
        shizuku = shizuku;
        koreader = koreader;
        gamenative = gamenative;
        morphe-library-m2 = morphe-library-m2;
        morphe-patches-gradle-plugin = morphe-patches-gradle-plugin;
        morphe-cli = morphe-cli;
        morphe-patches = morphe-patches;
        revanced-jadb-m2 = revanced-jadb-m2;
        revanced-apktool-m2 = revanced-apktool-m2;
        revanced-multidexlib2-m2 = revanced-multidexlib2-m2;
        revanced-patcher-m2 = revanced-patcher-m2;
        revanced-library-m2 = revanced-library-m2;
        revanced-patches-gradle-plugin = revanced-patches-gradle-plugin;
        revanced-patches = revanced-patches;
        revanced-cli = revanced-cli;
        fdroid-basic = fdroid-basic;
      };

      apkScope = lib.makeScope pkgs.newScope (
        _:
        scope1
        // {
          inherit sources;
          lspatchCli = lspatch-cli;
        }
      );

      apk = lib.filesystem.packagesFromDirectoryRecursive {
        inherit (apkScope) callPackage;
        directory = ./by-name-apk;
      };

      byNameScope = lib.makeScope pkgs.newScope (_: scope1 // { inherit apk; });
      byName = lib.filesystem.packagesFromDirectoryRecursive {
        inherit (byNameScope)
          callPackage
          newScope
          ;
        directory = ./by-name;
      };
    in
    {
      packages = scope1 // byName // apk;
    };
}
