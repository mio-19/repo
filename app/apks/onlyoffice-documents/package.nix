{
  mk-apk-package,
  lib,
  jdk17_headless,
  gradle_8_14_3,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-0-0
      ]);

      gradle = gradle_8_14_3;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "onlyoffice-documents";
      version = "9.3.1-707";

      src = fetchFromGitHub {
        owner = "ONLYOFFICE";
        repo = "documents-app-android";
        tag = "v${finalAttrs.version}";
        hash = "sha256-kSZLe3QAYc9y6wAHJab4JPHlab7qcWaVENR6at0OQZk=";
      };

      sourceRoot = "${finalAttrs.src.name}/app_manager";

      postUnpack = ''
        chmod -R u+w "$sourceRoot/.."
      '';

      gradleBuildTask = ":appmanager:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./onlyoffice_documents_deps.json;
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
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
      };

      postPatch = ''
        substituteInPlace build.gradle.kts \
          --replace-fail '        classpath(libs.google.services)' "" \
          --replace-fail '        classpath(libs.firebase.crashlytics.gradle)' ""

        substituteInPlace gradle.properties \
          --replace-fail 'android.nonTransitiveRClass=true' 'android.nonTransitiveRClass=false'

        substituteInPlace ../toolkit/libtoolkit/src/main/res/values/strings.xml \
          --replace-fail '</resources>' $'    <string name="account_type" translatable="false">com.onlyoffice.documents</string>\n    <string name="account_auth_type" translatable="false">com.onlyoffice.documents.token</string>\n</resources>'

        substituteInPlace appmanager/src/main/res/values/strings.xml \
          --replace-fail '</resources>' $'    <string name="account_type" translatable="false">com.onlyoffice.documents</string>\n    <string name="account_auth_type" translatable="false">com.onlyoffice.documents.token</string>\n    <string name="facebook_id" translatable="false"></string>\n    <string name="facebook_secret" translatable="false"></string>\n    <string name="facebook_host" translatable="false"></string>\n    <string name="facebook_id_sheme" translatable="false"></string>\n</resources>'

        substituteInPlace settings.gradle.kts \
          --replace-fail 'if (shouldIncludeEditors() == true) {' 'if (true) {'

        substituteInPlace appmanager/build.gradle.kts \
          --replace-fail '    id("com.google.firebase.crashlytics")' "" \
          --replace-fail 'apply(plugin = "com.google.gms.google-services")' "" \
          --replace-fail '    implementation(project(":libshared"))' $'    implementation(project(":libshared"))\n    implementation(project(":libsnapshot"))' \
          --replace-fail '            signingConfig = signingConfigs.getByName("onlyoffice")' ""
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-PwithEditors=false"
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_dir="appmanager/build/outputs/apk/release"
        apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
        test -n "$apk_name"
        apk_path="$apk_dir/$apk_name"
        test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/onlyoffice-documents.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "ONLYOFFICE Documents for Android (unsigned APK)";
        homepage = "https://github.com/ONLYOFFICE/documents-app-android";
        license = licenses.agpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "onlyoffice-documents.apk";
  signScriptName = "sign-onlyoffice-documents";
  fdroid = {
    appId = "com.onlyoffice.documents";
    metadataYml = ''
      Categories:
        - Office
      License: AGPL-3.0-only
      SourceCode: https://github.com/ONLYOFFICE/documents-app-android
      IssueTracker: https://github.com/ONLYOFFICE/documents-app-android/issues
      AutoName: ONLYOFFICE Documents
      Summary: Office suite for documents, sheets, and slides
      Description: |-
        ONLYOFFICE Documents is a mobile office suite for viewing and editing
        text documents, spreadsheets, and presentations.
        This package is built from source.
    '';
  };
}
