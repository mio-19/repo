{
  lib,
  jdk17_headless,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-34
    s.build-tools-33-0-1
    s.build-tools-34-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.5";
      hash = "sha256-nZJnhwZqCBc56CAIWDOLSmnoN8OoIaM6yp2wndSkECY=";
      defaultJava = jdk17_headless;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zotero-android";
  version = "1.0.19-32_3";

  src = fetchFromGitHub {
    owner = "zotero";
    repo = "zotero-android";
    tag = finalAttrs.version;
    hash = "sha256-XmNTetiUJJwGBSrzmKX1lvsydBSxh7y9KPT1OP7yFfs=";
  };

  gradleBuildTask = ":app:assembleBetaRelease";
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
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2";
    REALM_DISABLE_ANALYTICS = "true";
  };

  prePatch = ''
    substituteInPlace app/build.gradle.kts \
      --replace-fail 'import com.github.triplet.gradle.androidpublisher.ReleaseStatus' "" \
      --replace-fail 'import com.github.triplet.gradle.androidpublisher.ResolutionStrategy' "" \
      --replace-fail '    id("com.github.triplet.play") version "3.7.0"' "" \
      --replace-fail $'play {\n    track.set("internal")\n    defaultToAppBundles.set(true)\n    releaseStatus.set(ReleaseStatus.DRAFT)\n    resolutionStrategy.set(ResolutionStrategy.AUTO)\n}\n' "" \
      --replace-fail '            signingConfig = signingConfigs.getAt("release")' ""
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm644 \
      app/build/outputs/apk/beta/release/app-beta-release-unsigned.apk \
      "$out/zotero-android.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Zotero Android beta build from source (unsigned)";
    homepage = "https://github.com/zotero/zotero-android";
    license = licenses.agpl3Only;
    platforms = platforms.unix;
  };
})
