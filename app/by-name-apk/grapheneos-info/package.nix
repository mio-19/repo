{
  mk-apk-package,
  sources,
  lib,
  jdk21,
  jdk17,
  gradle-packages,
  stdenv,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  fetchpatch,
}:
let
  inherit (sources.grapheneos_info)
    src
    version
    ;

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-36-1-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.4.0";
          hash = "sha256-YOpyM1bYEmPoAC/sD8+eKw7uDAhQx6PXqwpj8szGAfM=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "grapheneos-info";
      inherit version src;

      patches = [
        (fetchpatch {
          name = "added release state display to info app";
          url = "https://github.com/GrapheneOS/Info/pull/56.diff";
          hash = "sha256-qMMHV6426FHw1QCg+JfpvmjO/qUvul6T/2Le7A2YQXI=";
        })
      ];

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./grapheneos_info_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21
        jdk17
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags =
        let
          postfix = if stdenv.isDarwin then "" else "/lib/openjdk";
        in
        [
          "-Dorg.gradle.java.installations.auto-download=false"
          "-Dorg.gradle.java.installations.paths=${jdk17}${postfix},${jdk21}${postfix}"
          "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
          "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
        ];

      installPhase = ''
        runHook preInstall
        apk_path="$(echo app/build/outputs/apk/release/*-unsigned.apk)"
        install -Dm644 "$apk_path" "$out/Info.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "GrapheneOS Info app (unsigned APK)";
        homepage = "https://github.com/GrapheneOS/Info";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "Info.apk";
  signScriptName = "sign-grapheneos-info";
}
