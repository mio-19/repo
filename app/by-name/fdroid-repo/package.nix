{
  callPackage,
  lib,
  stdenv,
  androidSdkBuilder,
  fdroid-basic,
  shizuku,
  appstore,
  droidspaces-oss,
  glimpse,
  forkgram,
  meshtastic,
  microg-re,
  thunderbird,
  lspatch-manager,
  vpnhotspot,
  meditrak,
  tuxguitar-android,
  zotero-android,
  meshcore-open,
  element-android,
  sunup,
  gamenative,
  archivetune,
  amethyst,
  tailscale,
  termux,
  termux-styling,
  termux-x11,
  emacs,
  haven,
  gadgetbridge,
  nix-on-droid,
  koreader,
  recorder,
  youtube-morphe,
  youtube-music-morphe,
  reddit-morphe,
  spotify-revanced,
  duolingo-revanced,
  microsoft-lens-revanced,
  bilibili-play,
  facebook-revanced,
  rednote,
  bilibili-cn,
  instagram-revanced,
}:
callPackage ./fdroid-repo.nix {
  androidSdk = androidSdkBuilder (s: [
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
      apkPath = "${forkgram}/${forkgram.meta.mainApk}";
      inherit (forkgram.meta) appId metadataYml;
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
      apkPath = "${tuxguitar-android}/tuxguitar-android.apk";
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
  ++ lib.optionals stdenv.isLinux [
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
      apkPath = "${termux-x11}/termux-x11.apk";
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
      apkPath = "${youtube-morphe}/youtube-morphe.apk";
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
      apkPath = "${youtube-music-morphe}/youtube-music-morphe.apk";
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
      apkPath = "${reddit-morphe}/reddit-morphe.apk";
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
      apkPath = "${spotify-revanced}/spotify-revanced.apk";
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
      apkPath = "${duolingo-revanced}/duolingo-revanced.apk";
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
      apkPath = "${microsoft-lens-revanced}/microsoft-lens-revanced.apk";
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
      apkPath = "${facebook-revanced}/facebook-revanced.apk";
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
      apkPath = "${bilibili-play}/bilibili-roaming.apk";
      metadataYml = ''
        Categories:
          - Video Players & Editors
        License: Proprietary
        SourceCode: https://github.com/yujincheng08/BiliRoaming
        IssueTracker: https://github.com/yujincheng08/BiliRoaming/issues
        AutoName: BiliBili Play
        Summary: BiliBili Google Play version patched with BiliRoaming via LSPatch
        Description: |-
          BiliBili Roaming embeds the latest BiliRoaming Xposed module
          using LSPatch so the official BiliBili client bypasses region
          locks and gains other enhancements without root.
      '';
    }
    {
      appId = "tv.danmaku.bili";
      apkPath = "${bilibili-cn}/bilibili-cn.apk";
      metadataYml = ''
        Categories:
          - Video Players & Editors
        License: Proprietary
        SourceCode: https://github.com/yujincheng08/BiliRoaming
        IssueTracker: https://github.com/yujincheng08/BiliRoaming/issues
        AutoName: BiliBili CN
        Summary: BiliBili patched with BiliRoaming via LSPatch
        Description: |-
          BiliBili Roaming embeds the latest BiliRoaming Xposed module
          using LSPatch so the official BiliBili client bypasses region
          locks and gains other enhancements without root.
      '';
    }
    {
      appId = "com.xingin.xhs";
      apkPath = "${rednote}/rednote.apk";
      metadataYml = ''
        Categories:
          - Internet
        License: Proprietary
        SourceCode: https://xiaohongshu.cn.uptodown.com/android/dw/1032665165
        IssueTracker: https://xiaohongshu.cn.uptodown.com/android/dw/1032665165
        AutoName: RedNote
        Summary: Patched Xiaohongshu APK
        Description: |-
          RedNote is a patched Xiaohongshu (Little Red Book) APK built with
          LSPatch
      '';
    }
    {
      appId = "com.instagram.android";
      apkPath = "${instagram-revanced}/instagram-revanced.apk";
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
}
