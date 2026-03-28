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

      immich = pkgs.callPackage ./immich {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      biliroaming = pkgs.callPackage ./biliroaming {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
      };

      bilibiliPlay = pkgs.callPackage ./bilibili {
        lspatchCli = lspatch-cli;
        biliroaming = biliroaming;
      };

      bilibiliCn = pkgs.callPackage ./bilibili-cn {
        lspatchCli = lspatch-cli;
        biliroaming = biliroaming;
      };

      rednote = pkgs.callPackage ./rednote {
        lspatchCli = lspatch-cli;
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

      mkPackagesFrom =
        scope: dir: names:
        lib.genAttrs names (name: scope.callPackage (dir + "/${name}/package.nix") { });

      apkPackageNames = [
        "amethyst"
        "appstore"
        "archivetune"
        "bilibili-cn"
        "bilibili-play"
        "droidspaces-oss"
        "duolingo-revanced"
        "element-android"
        "emacs"
        "facebook-revanced"
        "fdroid-basic"
        "forkgram"
        "gadgetbridge"
        "gamenative"
        "glimpse"
        "haven"
        "immich"
        "instagram-revanced"
        "kernelsu"
        "koreader"
        "lspatch-manager"
        "meditrak"
        "meshcore-open"
        "meshtastic"
        "microg-re"
        "microsoft-lens-revanced"
        "nix-on-droid"
        "recorder"
        "reddit-morphe"
        "rednote"
        "shizuku"
        "spotify-revanced"
        "sunup"
        "tailscale"
        "termux"
        "termux-styling"
        "termux-x11"
        "thunderbird"
        "tuxguitar-android"
        "vpnhotspot"
        "youtube-morphe"
        "youtube-music-morphe"
        "zotero-android"
      ];

      byNameAliasNames = [
        "biliroaming"
        "lspatch-cli"
        "morphe-cli"
        "morphe-library-m2"
        "morphe-patches"
        "morphe-patches-gradle-plugin"
        "revanced-apktool-m2"
        "revanced-cli"
        "revanced-jadb-m2"
        "revanced-library-m2"
        "revanced-multidexlib2-m2"
        "revanced-patcher-m2"
        "revanced-patches"
        "revanced-patches-gradle-plugin"
      ];

      fdroidRepoApkNames = [
        "fdroid-basic"
        "shizuku"
        "appstore"
        "droidspaces-oss"
        "glimpse"
        "forkgram"
        "meshtastic"
        "microg-re"
        "thunderbird"
        "lspatch-manager"
        "vpnhotspot"
        "meditrak"
        "tuxguitar-android"
        "zotero-android"
        "meshcore-open"
        "element-android"
        "sunup"
        "gamenative"
        "archivetune"
        "amethyst"
        "tailscale"
        "termux"
        "termux-styling"
        "termux-x11"
        "emacs"
        "haven"
        "gadgetbridge"
        "nix-on-droid"
        "kernelsu"
        "koreader"
        "recorder"
        "youtube-morphe"
        "youtube-music-morphe"
        "reddit-morphe"
        "spotify-revanced"
        "duolingo-revanced"
        "microsoft-lens-revanced"
        "facebook-revanced"
        "bilibili-play"
        "bilibili-cn"
        "rednote"
        "instagram-revanced"
      ];

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

      apkScope = lib.makeScope pkgs.newScope (_: scope1 // { raw = scope1; });
      byNameScope = lib.makeScope pkgs.newScope (_: scope1);

      apk = mkPackagesFrom apkScope ./by-name-apk apkPackageNames;

      byNameAliases = mkPackagesFrom byNameScope ./by-name byNameAliasNames;

      fdroidRepoApks = builtins.intersectAttrs (lib.genAttrs fdroidRepoApkNames (_: null)) apk;

      byName = {
        inherit (byNameAliases)
          biliroaming
          lspatch-cli
          morphe-cli
          morphe-library-m2
          morphe-patches
          morphe-patches-gradle-plugin
          revanced-apktool-m2
          revanced-cli
          revanced-jadb-m2
          revanced-library-m2
          revanced-multidexlib2-m2
          revanced-patcher-m2
          revanced-patches
          revanced-patches-gradle-plugin
          ;

        fdroid-repo = (
          pkgs.callPackage ./by-name/fdroid-repo/package.nix (
            {
              androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
            }
            // fdroidRepoApks
          )
        );

        sign-fdroid-repo = pkgs.callPackage ./by-name/sign-fdroid-repo/package.nix {
          androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
          fdroid-repo = byName.fdroid-repo;
        };
      };
    in
    {
      packages = scope1 // byName // apk;
    };
}
