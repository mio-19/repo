{
  mk-apk-package,
  overrides-from-source,
  gradle2nixBuilders,
  sources,
  lib,
  jdk25_headless,
  mergeLock,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  gradle_9_3_1,
}:
let
  inherit (sources.lineage_glimpse)
    src
    version
    ;

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-35-0-0
    s.build-tools-36-0-0
  ]);

  gradle = gradle_9_3_1;

  appPackage = gradle2nixBuilders.buildGradlePackage rec {
    pname = "glimpse";
    inherit version src gradle;

    lockFile = mergeLock [
      ./gradle.lock
      # [id: 'org.lineageos.generatebp', version: '1.28', apply: false] org.jetbrains.kotlin:kotlin-stdlib:2.2.0 org.jetbrains.kotlin:kotlin-reflect:2.2.0
      ./more.gradle.lock
    ];
    postPatch = ''
      substituteInPlace gradle/libs.versions.toml \
        --replace-fail 'generateBp = "+"' 'generateBp = "1.28"'
    '';
    overrides = overrides-from-source;
    buildJdk = jdk25_headless;

    nativeBuildInputs = [
      androidSdk
      gradle
      jdk25_headless
      apksigner
      writableTmpDirAsHomeHook
    ];

    dontUseGradleConfigure = true;

    env = {
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      export GRADLE_USER_HOME="$(mktemp -d)"
      export TERM=dumb
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      gradleFlagsArray+=(--no-daemon --init-script "$gradleInitScript" --offline)
    '';

    gradleFlags = [
      "-x"
      "lintVitalRelease"
      "-Dorg.gradle.java.home=${jdk25_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk25_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    ];

    gradleBuildFlags = ":app:assembleRelease";

    installPhase = ''
      runHook preInstall
      apk_path="$(echo app/build/outputs/apk/release/*-release-unsigned.apk)"
      install -Dm644 "$apk_path" "$out/glimpse.apk"
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
