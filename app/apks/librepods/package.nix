{
  mk-apk-package,
  buildGradlePackage,
  overrides-fromsrc,
  mergeLock,
  lib,
  fetchFromGitHub,
  jdk25_headless,
  gradle_9_4_1,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  version = "1.0.4";
  src = fetchFromGitHub {
    owner = "librepods-org";
    repo = "librepods";
    tag = "v${version}";
    hash = "sha256-R84mSviNoDAh5uQhUKBnsOf850E8fCHvDlWKWCBtZF4=";
  };
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-37-0
    s.build-tools-36-0-0
    s.build-tools-37-0-0
    s.ndk-30-0-14904198
    s.cmake-3-22-1
  ]);
  gradle = gradle_9_4_1;
  appPackage = buildGradlePackage rec {
    pname = "librepods";
    inherit version src gradle;
    sourceRoot = "${src.name}/android";
    lockFile = mergeLock [ ./gradle.lock ];
    overrides = overrides-fromsrc;
    buildJdk = jdk25_headless;

    gradleBuildFlags = ":app:assembleFossRelease";
    nativeBuildInputs = [
      androidSdk
      gradle
      jdk25_headless
      writableTmpDirAsHomeHook
    ];
    env = {
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/30.0.14904198";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/37.0.0/aapt2";
    };
    gradleFlags = [
      "-Dorg.gradle.java.home=${jdk25_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk25_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/37.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/37.0.0/aapt2"
    ];
    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      echo 'org.gradle.jvmargs=-Xmx6g -XX:MaxMetaspaceSize=1g' >> gradle.properties
    '';
    installPhase = ''
      runHook preInstall
      apkPath="$(find app/build/outputs/apk/foss/release -maxdepth 1 -type f -name '*.apk' -print -quit)"
      test -n "$apkPath"
      install -Dm644 "$apkPath" "$out/librepods.apk"
      runHook postInstall
    '';

    meta = with lib; {
      sourceProvenance = with sourceTypes; [ fromSource ];
      description = "LibrePods AirPods companion app built from source";
      homepage = "https://github.com/librepods-org/librepods";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "librepods.apk";
  signScriptName = "sign-librepods";
  fdroid = {
    appId = "me.kavishdevar.librepods";
    metadataYml = ''
      Categories:
        - Audio
        - Connectivity
      License: GPL-3.0-only
      WebSite: https://librepods.org
      SourceCode: https://github.com/librepods-org/librepods
      AutoName: LibrePods
      Summary: AirPods companion app liberated from Apple's ecosystem
      Description: |-
        LibrePods brings Apple AirPods features to Android including
        noise cancellation, transparency mode, conversational awareness,
        adaptive audio, and battery reporting. Built from source at v${version}.
    '';
  };
}
