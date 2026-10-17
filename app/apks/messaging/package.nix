{
  mk-apk-package,
  lib,
  stdenv,
  sources,
  jdk17_headless,
  jdk21_headless,
  gradle_9_6_1,
  androidSdkBuilder,
  writableTmpDirAsHomeHook,
  fetchpatch,
}:
let
  inherit (sources.grapheneos_messaging)
    src
    version
    ;

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-35
    s.platforms-android-36
    s."platforms-android-37-0"
    s."build-tools-36-0-0"
    s."build-tools-37-0-0"
    s.ndk-28-2-13676358
    s.cmake-3-22-1
  ]);

  gradle = gradle_9_6_1;

  appPackage = stdenv.mkDerivation (finalAttrs: {
    pname = "messaging";
    inherit version src;

    patches = [
      ./copy-verification-code.patch
      (fetchpatch {
        name = "Receive PDF attachments from MMS";
        url = "https://github.com/GrapheneOS/Messaging/pull/428.patch";
        hash = "sha256-ONWemmNcb7/8iab7B694eioAS9nJTLArVDI4Uigzb/4=";
      })
    ];

    postPatch = ''
      rm -f gradle/verification-metadata.xml
    '';

    gradleBuildTask = ":app:assembleRelease";
    gradleUpdateTask = ":app:assembleRelease";

    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./messaging_deps.json;
      silent = false;
      useBwrap = false;
    };

    nativeBuildInputs = [
      gradle
      jdk17_headless
      jdk21_headless
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = jdk17_headless.passthru.home;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
      NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    };

    preBuild = ''
      cat > local.properties <<EOF
      sdk.dir=${androidSdk}/share/android-sdk
      ndk.dir=${androidSdk}/share/android-sdk/ndk/28.2.13676358
      cmake.dir=${androidSdk}/share/android-sdk/cmake/3.22.1
      EOF

      echo "org.gradle.jvmargs=-Xmx4096m" >> gradle.properties
      cat >> gradle.properties <<EOF
      android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2
      org.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2
      EOF
    '';

    gradleFlags = [
      "-xlintVitalRelease"
      "-Dandroid.builder.sdkDownload=false"
      "-Dorg.gradle.java.home=${jdk17_headless.passthru.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk17_headless.passthru.home},${jdk21_headless.passthru.home}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    ];

    installPhase = ''
      runHook preInstall
      apk_file="$(find app/build/outputs/apk/release -name "*.apk" | head -n 1)"
      test -n "$apk_file"
      install -Dm644 "$apk_file" "$out/messaging.apk"
      runHook postInstall
    '';

    meta = with lib; {
      sourceProvenance = with sourceTypes; [ fromSource ];
      description = "GrapheneOS Messaging app with copy verification code support";
      homepage = "https://github.com/GrapheneOS/Messaging";
      license = licenses.asl20;
      platforms = platforms.linux;
    };
  });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "messaging.apk";
  signScriptName = "sign-messaging";
}
