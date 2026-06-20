{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  androidSdkBuilder,
  jdk21_headless,
  writableTmpDirAsHomeHook,
  runCommand,
  jre_headless,
  makeWrapper,
  gradle_8_13,
  git,
}:
let
  version = "1.0.5";

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.platforms-android-37-0
    s.build-tools-36-0-0
    s.build-tools-37-0-0
    s.ndk-29-0-13113456
    s.cmake-3-31-6
  ]);

  gradle = gradle_8_13;

  # We use the Vector commit cf1153e025318045d76ba64d0667e2a41c58ceaf (April 29, 2026)
  # which includes the :legacy module required by NPatch v1.0.5 but may not have the breaking API changes.
  # fetchSubmodules = true fetches all Vector sub-submodules (dobby, fmt, lsplant, etc.)
  # needed for the native patch-loader CMake build.
  coreSrc = fetchFromGitHub {
    owner = "HSSkyBoy";
    repo = "Vector";
    rev = "cf1153e025318045d76ba64d0667e2a41c58ceaf";
    fetchSubmodules = true;
    hash = "sha256-Y4LYSg8dKk6HIcVbG+h3k2iieqFDG/3k4I/h6jHoKgE=";
  };

  common = stdenv.mkDerivation (finalAttrs: {
    pname = "npatch-clionly";
    inherit version;

    # Manager source was deleted upstream from v1.0.1+; only the CLI jar is
    # built here by targeting :jar:buildRelease instead of the root buildRelease
    # task (which also requires the closed-source manager module).
    src = fetchFromGitHub {
      owner = "7723mod";
      repo = "NPatch";
      tag = "v1.0.5";
      fetchSubmodules = false;
      hash = "sha256-lqOBSjOm8M7RvS6r+1a8OKQtwig39rITf53KOlD46uU=";
    };

    postPatch = ''
      # Copy full core so settings.gradle.kts includeBuild("core") works
      # at Gradle configuration time — needed for both the normal build
      # and the mitmCache update script (which only runs postPatch, not postUnpack).
      # Remove the empty submodule placeholder first so cp -r doesn't nest inside it.
      rm -rf core
      cp -r --no-preserve=mode,ownership ${coreSrc} core

      substituteInPlace build.gradle.kts \
        --replace-fail 'val androidCompileNdkVersion by extra("29.0.13599879")' \
          'val androidCompileNdkVersion by extra("29.0.13113456")'
      # versionCode falls back to 0 without a .git repo; Android rejects 0
      substituteInPlace build.gradle.kts \
        --replace-fail 'val verCode by extra(commitCount)' \
          'val verCode by extra(10005)'

      substituteInPlace patch-loader/src/main/java/top/nkbe/npatch/loader/LSPApplication.java \
        --replace-fail 'XposedBridge.setLogPrinter' '// XposedBridge.setLogPrinter' || true

      substituteInPlace patch-loader/src/main/java/top/nkbe/npatch/loader/LSPLoader.java \
        --replace-fail 'if (NativeAPI.initializeNativeEntrypoint(libName, candidate)) {' \
                       'if (false) {' || true

      printf '\n' >> build.gradle.kts
      cat >> build.gradle.kts <<'EOF'
      allprojects {
          configurations.configureEach {
              resolutionStrategy.eachDependency {
                  if (requested.group == "androidx.savedstate"
                      && (requested.name == "savedstate-android" || requested.name == "savedstate-compose-android")
                      && (requested.version == "1.3.0" || requested.version == "1.3.1")
                  ) {
                      useVersion("1.3.3")
                      because("pin savedstate artifacts to versions present in offline lockfile")
                  }
                  // commons-lang3 3.14+ made MemberUtils methods private; pin to last compatible version
                  if (requested.group == "org.apache.commons" && requested.name == "commons-lang3") {
                      useVersion("3.13.0")
                      because("Vector core MemberUtilsX needs package-private MemberUtils API from 3.13.0")
                  }
              }
          }
      }
      EOF

      # AGP calls git during configuration; init a dummy repo so it doesn't fail
      git init
      git config user.email "nix@build"
      git config user.name "Nix"
      git commit --allow-empty -m "init"
    '';

    # Build only the jar subproject — avoids the closed-source manager module
    gradleBuildTask = ":jar:buildRelease";
    gradleUpdateTask = finalAttrs.gradleBuildTask;

    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./npatch_clionly_deps.json;
      silent = false;
      useBwrap = false;
    };

    nativeBuildInputs = [
      gradle
      jdk21_headless
      writableTmpDirAsHomeHook
      git
    ];

    env = {
      JAVA_HOME = jdk21_headless;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/29.0.13113456";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$PWD/.android"
      export GRADLE_USER_HOME="$PWD/.gradle"
      mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"

      echo "sdk.dir=$ANDROID_HOME" > local.properties
      echo "ndk.dir=$ANDROID_NDK_ROOT" >> local.properties
      cat >> gradle.properties <<EOF
      org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g
      android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.0.0/aapt2
      org.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.0.0/aapt2
      android.sdk.download=false
      EOF
    '';

    gradleFlags = [
      "--no-daemon"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    ];

    installPhase = ''
      runHook preInstall

      jar_path=$(find out/release -name "jar-v*.jar" | head -1)
      test -f "$jar_path"
      install -Dm644 "$jar_path" "$out/lspatch.jar"

      runHook postInstall
    '';

    meta = with lib; {
      description = "NPatch CLI tool built from source (v1.0.5, manager excluded)";
      homepage = "https://github.com/7723mod/NPatch";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
    };
  });
in
{
  inherit common;

  cli =
    runCommand "npatch-cli-${version}"
      {
        nativeBuildInputs = [ makeWrapper ];
        meta = with lib; {
          description = "NPatch CLI";
          homepage = "https://github.com/7723mod/NPatch";
          license = licenses.gpl3Only;
          platforms = platforms.unix;
          mainProgram = "npatch";
        };
      }
      ''
        mkdir -p $out/bin
        makeWrapper ${lib.getExe jre_headless} "$out/bin/npatch" --add-flags -jar --add-flags "${common}/lspatch.jar"
      '';
}
