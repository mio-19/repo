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
}:
let
  version = "0.8-unstable-20260330";

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-1-0
    s.ndk-29-0-13113456
    s.cmake-3-31-6
  ]);

  gradle = gradle_8_13;

  common = stdenv.mkDerivation (finalAttrs: {
    pname = "npatch";
    inherit version;

    src = fetchFromGitHub {
      owner = "7723mod";
      repo = "NPatch";
      rev = "41872d8261a956a8bde1b51cf29914bb2e9f36df";
      fetchSubmodules = true;
      hash = "sha256-S/0jfMwZEETnuQ5lkKD1I0rFVqVe3zsTb8/rdwMsim8=";
    };

    patches = [
      ./build-gradle-fixed-version.patch
      ./build-gradle-disable-cxx-modules.patch
    ];

    postPatch = ''
      substituteInPlace build.gradle.kts \
        --replace-fail 'val androidCompileNdkVersion by extra("29.0.13599879")' \
          'val androidCompileNdkVersion by extra("29.0.13113456")'
      substituteInPlace gradle/lspatch.versions.toml \
        --replace-fail 'compose-bom = "2025.12.01"' \
          'compose-bom = "2025.11.00"' \
        --replace-fail 'core-ktx = "1.17.0"' \
          'core-ktx = "1.16.0"' \
        --replace-fail 'androidx-lifecycle-viewmodel-compose = "androidx.lifecycle:lifecycle-viewmodel-compose:2.9.2"' \
          'androidx-lifecycle-viewmodel-compose = "androidx.lifecycle:lifecycle-viewmodel-compose:2.9.4"'
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
              }
          }
      }
      EOF
    '';

    gradleBuildTask = "buildRelease";
    gradleUpdateTask = finalAttrs.gradleBuildTask;

    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./lspatch_deps.json;
      silent = false;
      useBwrap = false;
    };

    nativeBuildInputs = [
      gradle
      jdk21_headless
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = jdk21_headless;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/29.0.13113456";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$PWD/.android"
      export GRADLE_USER_HOME="$PWD/.gradle"
      mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"

      echo "sdk.dir=$ANDROID_HOME" > local.properties
      echo "ndk.dir=$ANDROID_NDK_ROOT" >> local.properties
      cat >> gradle.properties <<EOF
      org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g
      android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.1.0/aapt2
      org.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.1.0/aapt2
      EOF
    '';

    gradleFlags = [
      "-xlintVitalRelease"
      "--no-daemon"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
    ];

    installPhase = ''
      runHook preInstall

      jar_path="out/release/jar-v0.7.4-20260315-release.jar"
      apk_path="out/release/NPatch-v0.7.4-20260315-release.apk"
      test -f "$jar_path"
      test -f "$apk_path"

      install -Dm644 "$jar_path" "$out/lspatch.jar"
      install -Dm644 "$apk_path" "$out/lspatch-manager.apk"

      runHook postInstall
    '';

    meta = with lib; {
      description = "LSPatch CLI and manager app built from source";
      homepage = "https://github.com/JingMatrix/LSPatch";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
    };
  });
in
{
  inherit common;

  cli =
    runCommand "lspatch-cli-${version}"
      {
        nativeBuildInputs = [ makeWrapper ];
        meta = with lib; {
          description = "LSPatch CLI";
          homepage = "https://github.com/JingMatrix/LSPatch";
          license = licenses.gpl3Only;
          platforms = platforms.unix;
          mainProgram = "lspatch";
        };
      }
      ''
        mkdir -p $out/bin
        makeWrapper ${lib.getExe jre_headless} "$out/bin/lspatch" --add-flags -jar --add-flags "${common}/lspatch.jar"
      '';

  manager = runCommand "lspatch-manager-${version}" { } ''
    install -Dm644 "${common}/lspatch-manager.apk" "$out/lspatch-manager.apk"
  '';
}
