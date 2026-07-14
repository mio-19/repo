{
  agp-resolution,

  androidSdkBuilder,
  fetchgit,
  overrides-fromsrc,
  buildGradlePackage,
  gradle_9_4_1,
  jdk25_headless,
  lib,
  mkSignScript,
  writableTmpDirAsHomeHook,
  overrides-fromsrc-updated,
  mergeLock,
}:

let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s."platforms-android-37-0"
    s."build-tools-36-0-0"
    s."build-tools-37-0-0"
  ]);

  gradle = gradle_9_4_1;
in
buildGradlePackage rec {
  pname = "fdroid-basic";
  version = "2.0-alpha11";

  src = fetchgit {
    url = "https://gitlab.com/fdroid/fdroidclient.git";
    tag = version;
    hash = "sha256-nXZXASrwBzhVN3LRQeR3Wfangy/aVk5DihVos1kc1Do=";
  };

  patches = [ ./version-name-update.patch ];

  lockFile = mergeLock [
    ./gradle.lock
    ./missing.lock
    ../pdfviewer/gradle.lock
  ];

  inherit gradle;

  overrides = overrides-fromsrc-updated;

  buildJdk = jdk25_headless;

  nativeBuildInputs = [
    androidSdk
    jdk25_headless

    writableTmpDirAsHomeHook
  ];

  postPatch = ''
    rm -f gradle/verification-metadata.xml
    echo "Removed gradle/verification-metadata.xml so the source-built java libraries overrides is not rejected by upstream checksum verification."

    substituteInPlace app/build.gradle.kts \
      --replace-fail '  lint {' $'  lint {\n    checkReleaseBuilds = false' \
      --replace-fail 'versionNameSuffix = "-$gitHash"' 'versionNameSuffix = "-unknown"'
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  env = {
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/37.0.0/aapt2";
  };

  gradleFlags = [
    "--console=plain"
    "-Dorg.gradle.java.home=${jdk25_headless.home}"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk25_headless}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/37.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/37.0.0/aapt2"
  ];

  gradleBuildFlags = ":app:assembleBasicDefaultRelease";

  installPhase = ''
    runHook preInstall
    apk_path="app/build/outputs/apk/basicDefault/release/app-basic-default-release-unsigned.apk"
    test -f "$apk_path"
    install -Dm644 "$apk_path" "$out/fdroid-basic.apk"
    runHook postInstall
  '';

  passthru.signScript = mkSignScript {
    name = "sign-fdroid-basic";
    apkPath = "${placeholder "out"}/fdroid-basic.apk";
    defaultOut = "fdroid-basic-signed.apk";
  };

  meta = with lib; {
    description = "F-Droid Basic app built from source (unsigned)";
    homepage = "https://gitlab.com/fdroid/fdroidclient";
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
    mainApk = "fdroid-basic.apk";
    appId = "org.fdroid.basic";
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
  };
}
