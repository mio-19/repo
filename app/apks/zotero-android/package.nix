{
  mk-apk-package,
  lib,
  jdk17_headless,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
  fetchpatch,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.build-tools-33-0-1
        s.build-tools-35-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.2.1";
          hash = "sha256-cvRMn468sa9Dg49F7lxKqcVESJizRoqz9K97YHbFvD8=";
          defaultJava = jdk17_headless;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "zotero-android";
      version = "1.0.0-237";

      src = fetchFromGitHub {
        owner = "zotero";
        repo = "zotero-android";
        # 1.0.19-32_3 sorts newer than 1.0.0-237, but it is from an older
        # upstream release series. Keep 1.0.0-* unless a newer same-series tag appears.
        # Upstream has multiple tag naming schemes. Check the tags page for the
        # latest 1.0.0-* tag by time, not raw version ordering:
        # https://github.com/zotero/zotero-android/tags
        tag = finalAttrs.version;
        hash = "sha256-9o/zPRoJWezbPXCsfirYqYvhB71VW+dBbNefwInIGQI=";
      };

      patches = [
        (fetchpatch {
          name = "Add a button to fetch all";
          url = "https://github.com/zotero/zotero-android/pull/291.patch";
          hash = "sha256-gdDpOwy5PUeDksqxz0B1DMHSSgH3nyj0vdQGSd0oNG4=";
        })
        (fetchpatch {
          name = "Add volume buttons zoom";
          url = "https://github.com/zotero/zotero-android/pull/298.diff";
          hash = "sha256-I3BU1rkTx2YiQnRh/7vjv2k8ahCHeVSS8jT3XAgEklI=";
        })
      ];

      gradleBuildTask = ":app:assembleInternalRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./zotero_android_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless
        apksigner
        writableTmpDirAsHomeHook
        git
      ];

      env = {
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
        REALM_DISABLE_ANALYTICS = "true";
      };

      prePatch = ''
        substituteInPlace app/build.gradle.kts \
          --replace-fail 'import com.github.triplet.gradle.androidpublisher.ResolutionStrategy' "" \
          --replace-fail '    id("com.github.triplet.play") version "3.12.1"' "" \
          --replace-fail $'play {\n    track.set("internal")\n    defaultToAppBundles.set(true)\n    resolutionStrategy.set(ResolutionStrategy.AUTO)\n}\n' "" \
          --replace-fail '            signingConfig = signingConfigs.getAt("release")' ""
        echo cyB6IEYgdCBsIEYgUCAyIDEgYiA5IF8gXyBsIFEgMSBsIFEgTCB2IFQgWCBNIHcgeiBHIHogYSBxIHMgTiA0IDUgMCBJIGkgMyBTIHcgYyBCIEYgTSAxIFggZyBNIEQgeSB1IDQgaSBuIFEgaCA5IDAgQSBNIHAgVCBCIG8gMiA5IDQgVSB5IHkgLSB1IHogdCBTIEggZyBRIHQgOSA5IFkgSiBYIDYgVCAzIEkgRSBSIGwgRyBrIHkgeiBqIEkgdCBVIEMgUSAyIF8gNCBkIFEgMyB1IEggXyBsIFogYiBVIFogeCA1IDMgZCAyIGkgNiBvIGEgSSB1IGwgaCAzIDQgcyA3IFkgdiBRIHEgayB2IDQgRyBCIFQgdCBKIFYgWCB4IDAgSCBWIDEgZiByIDMgWSBmIHEgdCBOIG0geSBBIFAgXyBSIC0gcSBwIHcgOCB1IC0gNSBMIFggUyB5IDcgRyA5IFAgeSBUIEIgQyBVIGMgZyA0IFAgSCBoIFAgRiB2IEkgRyAtIEcgUCByIGIgYyA5IE8gdiBzIGIgVyBSIEggQiAtIC0gcCBDIGIgMiBTIDkgRiBYIFggNCBRIDUgeSBWIFIgUSBMIFogaSBqIEUgUSBsIFAgOCBsIHYgXyBuIFAgMyBJIHkgdyB4IC0gSCA1IDMgNSBEIHkgZiBGIEkgcyB1IHkgYyB1IHQgdyA4IHMgSCBmIHogMSBNIGsgMSBVIFIgciBlIG8gWSA5IDggUiBtIEMgZSA1IEogeiA4IFAgVCBhIHMgNCBCIC0gWiBvIGEgQiA5IEwgZyBTIGEgaCBEIDggeiBvIFMgeCB3IEkgNCByIEogSSBTIFAgViBQIDMgeSB3IEcgeSBQIFggeCBJIHkgVCBHIDEgQSBaIEIgbiBFIEMgVyBsIGQgRSBiIEUgaiA0IEEgeiBUIGwgQyB2IDAgNCBiIEQgNCB5IHMgNiB5IHogdCB1IHIgVSB0IFcgaiBxIEwgeCByIGkgNSBwIGcgZyBSIFcgdyA5IFcgRSBPIGkgSSBMIEggbSA0IFEgRCBaIFQgbiBNIHcgRiBEIHMgOCBxIEcgQSB1IFIgUSBhIGggUSBwIEkgaiAzIEUgbCB2IEsgbSBUIG4gMCBaIHogViBIIEsgViBsIGwgayA0IEogVCAtIEYgeSBzIE0gLSBGIDggVCBwIDIgWiBsIGwgTSBuIEYgeCB3IG0gaSBuIHQgbSBkIFcgRyBoIGwgRyBNIDMgVCBhIF8gcCBNIDYgQSBjIDcgYSBfIDUgSyBTIFggZSBLIHUgcCBqIEEgdSBQIEcgcCBfIEwgbSA1IEkgQyB1IGcgWiBRIFYgMSA5IFogNCBhIDUgYyBOIGogeCBuIDMgTyBSIEQgeSBoIGYgdyBiIE0gciBZIGYgWSBJIEogVCBiIEogTyB6IHMgbCBNIEEgZyBPIGIgdSBTIDUgeSAzIDUgbyB3IFAgaiBoIE4gSyAzIFcgSiBpIGcgMCB0IFkgNSBnIEYgaSBWIFAgNiBPIEUgWiBuIEkgZCAyIEcgcCB3IG0gVCBxIDQgSyBGIG0geiBNIF8gcCBYIFkgRSBPIHUgNiA5IFMgRCBhIE4gRCBwIEggXyBzIHcgTSB2IDUgTCBzIE0gSiBvIEkgSiBMIHQgeiBoIGEgSSBGIGggeSBnIEwgaiBVIDQgdCBJIGYgVyAK | base64 -d > pspdfkit-key.txt
      '';

      postPatch = ''
        find app/src/main/res -name "*.orig" -delete
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 \
          app/build/outputs/apk/internal/release/app-internal-release-unsigned.apk \
          "$out/zotero-android.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Zotero Android beta build from source (unsigned)";
        homepage = "https://github.com/zotero/zotero-android";
        license = licenses.agpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "zotero-android.apk";
  signScriptName = "sign-zotero-android";
  fdroid = {
    appId = "org.zotero.android";
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
  };
}
