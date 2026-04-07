{
  apksigner,
  androidSdkBuilder,
  error_prone_annotations_2_27_0,
  error_prone_annotations_2_28_0,
  fetchgit,
  failureaccess_1_0_1,
  failureaccess_1_0_2,
  gradle-packages,
  gradle2nixBuilders,
  guava_33_3_1_jre,
  j2objc_annotations_2_8,
  j2objc_annotations_3_0_0,
  jdk21,
  lib,
  mkSignScript,
  slf4j_api_2_0_17,
  writableTmpDirAsHomeHook,
}:

let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "9.3.1";
      hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
      defaultJava = jdk21;
    }).wrapped;
in
gradle2nixBuilders.buildGradlePackage rec {
  pname = "fdroid-basic";
  version = "2.0-alpha7";

  src = fetchgit {
    url = "https://gitlab.com/fdroid/fdroidclient.git";
    tag = version;
    hash = "sha256-2aKQAz8vEJjauhHGVt7ZhmqkbYuK/c4ztYLHNQIjZZ0=";
  };

  lockFile = ./gradle.lock;

  inherit gradle;

  overrides = {
    "com.google.guava:guava:33.3.1-jre" = {
      "guava-33.3.1-jre.jar" = _: "${guava_33_3_1_jre}/guava-33.3.1-jre.jar";
      "guava-33.3.1-jre.module" = _: "${guava_33_3_1_jre}/guava-33.3.1-jre.module";
      "guava-33.3.1-jre.pom" = _: "${guava_33_3_1_jre}/guava-33.3.1-jre.pom";
    };
    "com.google.guava:guava-parent:33.3.1-jre" = {
      "guava-parent-33.3.1-jre.pom" = _: "${guava_33_3_1_jre}/guava-parent-33.3.1-jre.pom";
    };
    "com.google.guava:failureaccess:1.0.1" = {
      "failureaccess-1.0.1.jar" = _: "${failureaccess_1_0_1}/failureaccess-1.0.1.jar";
      "failureaccess-1.0.1.pom" = _: "${failureaccess_1_0_1}/failureaccess-1.0.1.pom";
    };
    "com.google.guava:failureaccess:1.0.2" = {
      "failureaccess-1.0.2.jar" = _: "${failureaccess_1_0_2}/failureaccess-1.0.2.jar";
      "failureaccess-1.0.2.pom" = _: "${failureaccess_1_0_2}/failureaccess-1.0.2.pom";
    };
    "com.google.guava:guava-parent:26.0-android" = {
      "guava-parent-26.0-android.pom" = _: "${failureaccess_1_0_2}/guava-parent-26.0-android.pom";
    };
    "com.google.errorprone:error_prone_annotations:2.27.0" = {
      "error_prone_annotations-2.27.0.jar" =
        _: "${error_prone_annotations_2_27_0}/error_prone_annotations-2.27.0.jar";
      "error_prone_annotations-2.27.0.pom" =
        _: "${error_prone_annotations_2_27_0}/error_prone_annotations-2.27.0.pom";
    };
    "com.google.errorprone:error_prone_annotations:2.28.0" = {
      "error_prone_annotations-2.28.0.jar" =
        _: "${error_prone_annotations_2_28_0}/error_prone_annotations-2.28.0.jar";
      "error_prone_annotations-2.28.0.pom" =
        _: "${error_prone_annotations_2_28_0}/error_prone_annotations-2.28.0.pom";
    };
    "com.google.errorprone:error_prone_parent:2.27.0" = {
      "error_prone_parent-2.27.0.pom" =
        _: "${error_prone_annotations_2_27_0}/error_prone_parent-2.27.0.pom";
    };
    "com.google.errorprone:error_prone_parent:2.28.0" = {
      "error_prone_parent-2.28.0.pom" =
        _: "${error_prone_annotations_2_28_0}/error_prone_parent-2.28.0.pom";
    };
    "com.google.j2objc:j2objc-annotations:2.8" = {
      "j2objc-annotations-2.8.jar" = _: "${j2objc_annotations_2_8}/j2objc-annotations-2.8.jar";
      "j2objc-annotations-2.8.pom" = _: "${j2objc_annotations_2_8}/j2objc-annotations-2.8.pom";
    };
    "com.google.j2objc:j2objc-annotations:3.0.0" = {
      "j2objc-annotations-3.0.0.jar" = _: "${j2objc_annotations_3_0_0}/j2objc-annotations-3.0.0.jar";
      "j2objc-annotations-3.0.0.pom" = _: "${j2objc_annotations_3_0_0}/j2objc-annotations-3.0.0.pom";
    };
    "org.slf4j:slf4j-api:2.0.17" = {
      "slf4j-api-2.0.17.jar" = _: "${slf4j_api_2_0_17}/slf4j-api-2.0.17.jar";
      "slf4j-api-2.0.17.pom" = _: "${slf4j_api_2_0_17}/slf4j-api-2.0.17.pom";
    };
    "org.slf4j:slf4j-bom:2.0.17" = {
      "slf4j-bom-2.0.17.pom" = _: "${slf4j_api_2_0_17}/slf4j-bom-2.0.17.pom";
    };
    "org.slf4j:slf4j-parent:2.0.17" = {
      "slf4j-parent-2.0.17.pom" = _: "${slf4j_api_2_0_17}/slf4j-parent-2.0.17.pom";
    };
  };

  buildJdk = jdk21;

  nativeBuildInputs = [
    androidSdk
    jdk21
    apksigner
    writableTmpDirAsHomeHook
  ];

  postPatch = ''
    rm -f gradle/verification-metadata.xml
    echo "Removed gradle/verification-metadata.xml so the source-built Guava override is not rejected by upstream checksum verification."

    pluginResolutionBlock=$'pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {\n                def agpVersion = requested.version ?: "9.1.0"\n                useModule("com.android.tools.build:gradle:''${agpVersion}")\n            }\n        }\n    }\n'
    substituteInPlace settings.gradle \
      --replace-fail "pluginManagement {" "$pluginResolutionBlock"
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
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
  };

  gradleFlags = [
    "--console=plain"
    "-Dorg.gradle.java.home=${jdk21.home}"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk21}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
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
