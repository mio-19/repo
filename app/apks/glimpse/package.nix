{
  stdenv,
  mk-apk-package,
  overrides-fromsrc,
  gradle2nixBuilders,
  sources,
  lib,
  jdk25_headless,
  mergeLock,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  gradle_9_4_1,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-0-0
  ]);

  gradle = gradle_9_4_1;

  appPackage = gradle2nixBuilders.buildGradlePackage rec {
    pname = "glimpse";
    inherit (sources.lineage_glimpse)
      src
      version
      ;
    inherit gradle;

    lockFile = mergeLock [
      gradle.unwrapped.passthru.lockFile
      ./gradle.lock
      # [id: 'org.lineageos.generatebp', version: '1.28', apply: false] org.jetbrains.kotlin:kotlin-stdlib:2.2.0 org.jetbrains.kotlin:kotlin-reflect:2.2.0
      ./more.gradle.lock
      # generateBp 1.32
      ./bp.gradle.lock
      # com.android.tools.lint:lint-gradle:32.1.0. only needed on darwin for some reason
      ../archivetune/gradle.lock
    ];
    postPatch = ''
      substituteInPlace gradle/libs.versions.toml \
        --replace-fail 'generateBp = "+"' 'generateBp = "1.32"'
    '';
    overrides = overrides-fromsrc;
    buildJdk = jdk25_headless;

    nativeBuildInputs = [
      androidSdk
      gradle
      jdk25_headless
      apksigner
      writableTmpDirAsHomeHook
    ];

    env = {
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    };

    gradleFlags = [
      "-Dorg.gradle.java.home=${jdk25_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk25_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    ];

    gradleBuildFlags = ":app:assembleRelease";

    preBuild = lib.optionalString stdenv.isDarwin ''
      export ANDROID_USER_HOME="$HOME/.android"
      mkdir -p "$ANDROID_USER_HOME"
    '';

    installPhase = ''
      runHook preInstall
      install -Dm644 app/build/outputs/apk/release/app-release-unsigned.apk "$out/glimpse.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "LineageOS Glimpse photo gallery app (unsigned APK)";
      homepage = "https://github.com/LineageOS/android_packages_apps_Glimpse";
      license = licenses.asl20;
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "glimpse.apk";
  signScriptName = "sign-glimpse";
  fdroid = {
    appId = "org.lineageos.glimpse";
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
  };
}
