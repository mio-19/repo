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

      scope1 = {
        androidSdkBuilder = inputs.android-nixpkgs.sdk.${system};
        forkgram = forkgram.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-forkgram";
            apkPath = "${forkgram}/forkgram.apk";
            defaultOut = "forkgram-signed.apk";
          };
        });

        meshtastic = meshtastic.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-meshtastic";
            apkPath = "${meshtastic}/meshtastic.apk";
            defaultOut = "meshtastic-signed.apk";
          };
        });

        droidspaces-oss = droidspaces-oss.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-droidspaces-oss";
            apkPath = "${droidspaces-oss}/droidspaces-oss.apk";
            defaultOut = "droidspaces-oss-signed.apk";
          };
        });

        microg-re = microg-re.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-microg-re";
            apkPath = "${microg-re}/microg-re.apk";
            defaultOut = "microg-re-signed.apk";
          };
        });

        youtube-morphe = youtubeMorphe.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-youtube-morphe";
            apkPath = "${youtubeMorphe}/youtube-morphe.apk";
            defaultOut = "youtube-morphe-signed.apk";
          };
        });

        youtube-music-morphe = youtubeMusicMorphe.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-youtube-music-morphe";
            apkPath = "${youtubeMusicMorphe}/youtube-music-morphe.apk";
            defaultOut = "youtube-music-morphe-signed.apk";
          };
        });

        rednote = rednote.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-rednote";
            apkPath = "${rednote}/rednote.apk";
            defaultOut = "rednote-signed.apk";
          };
        });

        reddit-morphe = redditMorphe.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-reddit-morphe";
            apkPath = "${redditMorphe}/reddit-morphe.apk";
            defaultOut = "reddit-morphe-signed.apk";
          };
        });

        spotify-revanced = spotifyRevanced.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-spotify-revanced";
            apkPath = "${spotifyRevanced}/spotify-revanced.apk";
            defaultOut = "spotify-revanced-signed.apk";
          };
        });

        duolingo-revanced = duolingoRevanced.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-duolingo-revanced";
            apkPath = "${duolingoRevanced}/duolingo-revanced.apk";
            defaultOut = "duolingo-revanced-signed.apk";
          };
        });

        microsoft-lens-revanced = microsoftLensRevanced.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-microsoft-lens-revanced";
            apkPath = "${microsoftLensRevanced}/microsoft-lens-revanced.apk";
            defaultOut = "microsoft-lens-revanced-signed.apk";
          };
        });

        facebook-revanced = facebookRevanced.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-facebook-revanced";
            apkPath = "${facebookRevanced}/facebook-revanced.apk";
            defaultOut = "facebook-revanced-signed.apk";
          };
        });

        immich = immich.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-immich";
            apkPath = "${immich}/immich.apk";
            defaultOut = "immich-signed.apk";
          };
        });

        biliroaming = biliroaming;

        bilibili-play = bilibiliPlay.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-bilibili-roaming";
            apkPath = "${bilibiliPlay}/bilibili-roaming.apk";
            defaultOut = "bilibili-roaming-signed.apk";
          };
        });

        bilibili-cn = bilibiliCn.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-bilibili-cn";
            apkPath = "${bilibiliCn}/bilibili-cn.apk";
            defaultOut = "bilibili-cn-signed.apk";
          };
        });

        instagram-revanced = instagramRevanced.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-instagram-revanced";
            apkPath = "${instagramRevanced}/instagram-revanced.apk";
            defaultOut = "instagram-revanced-signed.apk";
          };
        });

        thunderbird = thunderbird.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-thunderbird";
            apkPath = "${thunderbird}/thunderbird.apk";
            defaultOut = "thunderbird-signed.apk";
          };
        });

        emacs = emacs.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-emacs";
            apkPath = "${emacs}/emacs.apk";
            defaultOut = "emacs-signed.apk";
          };
        });

        lspatch-cli = lspatch-cli;

        lspatch-manager = lspatch-manager.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-lspatch-manager";
            apkPath = "${lspatch-manager}/lspatch-manager.apk";
            defaultOut = "lspatch-manager-signed.apk";
          };
        });

        nix-on-droid = nix-on-droid.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-nix-on-droid";
            apkPath = "${nix-on-droid}/nix-on-droid.apk";
            defaultOut = "nix-on-droid-signed.apk";
          };
        });

        tailscale = tailscale.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-tailscale";
            apkPath = "${tailscale}/tailscale.apk";
            defaultOut = "tailscale-signed.apk";
          };
        });

        termux = termux.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-termux";
            apkPath = "${termux}/termux.apk";
            defaultOut = "termux-signed.apk";
          };
        });

        termux-styling = termux-styling.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-termux-styling";
            apkPath = "${termux-styling}/termux-styling.apk";
            defaultOut = "termux-styling-signed.apk";
          };
        });

        termux-x11 = termuxX11.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-termux-x11";
            apkPath = "${termuxX11}/termux-x11.apk";
            defaultOut = "termux-x11-signed.apk";
          };
        });

        kernelsu = kernelsu.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-kernelsu";
            apkPath = "${kernelsu}/kernelsu.apk";
            defaultOut = "kernelsu-signed.apk";
          };
        });

        gadgetbridge = gadgetbridge.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-gadgetbridge";
            apkPath = "${gadgetbridge}/gadgetbridge.apk";
            defaultOut = "gadgetbridge-signed.apk";
          };
        });

        vpnhotspot = vpnhotspot.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-vpnhotspot";
            apkPath = "${vpnhotspot}/vpnhotspot.apk";
            defaultOut = "vpnhotspot-signed.apk";
          };
        });

        meditrak = meditrak.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-meditrak";
            apkPath = "${meditrak}/meditrak.apk";
            defaultOut = "meditrak-signed.apk";
          };
        });

        zotero-android = zotero-android.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-zotero-android";
            apkPath = "${zotero-android}/zotero-android.apk";
            defaultOut = "zotero-android-signed.apk";
          };
        });

        tuxguitar-android = tuxguitar.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-tuxguitar-android";
            apkPath = "${tuxguitar}/tuxguitar-android.apk";
            defaultOut = "tuxguitar-android-signed.apk";
          };
        });

        meshcore-open = meshcore-open.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-meshcore-open";
            apkPath = "${meshcore-open}/meshcore-open.apk";
            defaultOut = "meshcore-open-signed.apk";
          };
        });

        element-android = element-android.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-element-android";
            apkPath = "${element-android}/element-android.apk";
            defaultOut = "element-android-signed.apk";
          };
        });
        glimpse = glimpse.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-glimpse";
            apkPath = "${glimpse}/glimpse.apk";
            defaultOut = "glimpse-signed.apk";
          };
        });

        sunup = sunup.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-sunup";
            apkPath = "${sunup}/sunup.apk";
            defaultOut = "sunup-signed.apk";
          };
        });

        recorder = recorder.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-recorder";
            apkPath = "${recorder}/recorder.apk";
            defaultOut = "recorder-signed.apk";
          };
        });

        haven = haven.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-haven";
            apkPath = "${haven}/haven.apk";
            defaultOut = "haven-signed.apk";
          };
        });

        archivetune = archivetune.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-archivetune";
            apkPath = "${archivetune}/archivetune.apk";
            defaultOut = "archivetune-signed.apk";
          };
        });
        amethyst = amethyst.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-amethyst";
            apkPath = "${amethyst}/amethyst.apk";
            defaultOut = "amethyst-signed.apk";
          };
        });

        appstore = appstore.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-appstore";
            apkPath = "${appstore}/appstore.apk";
            defaultOut = "appstore-signed.apk";
          };
        });

        shizuku = shizuku.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-shizuku";
            apkPath = "${shizuku}/shizuku.apk";
            defaultOut = "shizuku-signed.apk";
          };
        });

        koreader = koreader.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-koreader";
            apkPath = "${koreader}/koreader.apk";
            defaultOut = "koreader-signed.apk";
          };
        });
        gamenative = gamenative.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-gamenative";
            apkPath = "${gamenative}/gamenative.apk";
            defaultOut = "gamenative-signed.apk";
          };
        });
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

        fdroid-basic = fdroid-basic.overrideAttrs (_: {
          passthru.signScript = mkSignScript {
            name = "sign-fdroid-basic";
            apkPath = "${fdroid-basic}/fdroid-basic.apk";
            defaultOut = "fdroid-basic-signed.apk";
          };
        });

      };
      scope2 = lib.makeScope pkgs.newScope (self: scope1);
    in
    {
      packages =
        lib.filesystem.packagesFromDirectoryRecursive {
          inherit (scope2) callPackage newScope;
          directory = ./by-name;
        }
        // scope1;
    };
}
