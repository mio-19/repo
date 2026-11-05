{
  mk-apk-package,
  buildGradlePackage,
  overrides-fromsrc,
  mergeLock,
  lib,
  fetchFromGitHub,
  fetchgit,
  git,
  jdk21_headless,
  jdk25_headless,
  gradle_9_4_1,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  version = "0.0.6";
  src = fetchFromGitHub {
    owner = "Droid-VM";
    repo = "DroidVM";
    tag = version;
    hash = "sha256-u+tfNBv/RebVofRhHpIRiSRpewIb+142q1QR5DbeLoE=";
  };
  jsoncpp = fetchFromGitHub {
    owner = "open-source-parsers";
    repo = "jsoncpp";
    rev = "3455302847cf1e4671f1d8f5fa953fd46a7b1404";
    hash = "sha256-rf8d2UNTVEZhuiyChK2XnUbfGDvsfXnKADhaSp8qBwQ=";
  };
  libvncserver = fetchFromGitHub {
    owner = "Droid-VM";
    repo = "libvncserver";
    rev = "1ee1a4afcb5322db0e64f6ec6b00dac5a06af94b";
    hash = "sha256-B9ouXzInth09DKvlWObdB54DlDL/75QByE/I9O/iV08=";
  };
  prebuilts = fetchFromGitHub {
    owner = "Droid-VM";
    repo = "DroidVM-Prebuilts";
    rev = "b5515e428d12cabe0dfee1fb3e9d0f3d5c4aa24b";
    hash = "sha256-leB4W7MyTHPjI4gfaHb+FEaYkQXJGScTrkhufIqEqzg=";
  };
  udisasm = fetchgit {
    url = "https://gitlab.com/bztsrc/udisasm";
    rev = "6cec94b5634e1c9025af17527688f502f523fd25";
    hash = "sha256-dYWT+VXtM9YJGron8YUB55zveKPx1EGqVJkqRq5lLOs=";
  };
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-0-0
    s.ndk-30-0-14904198
    s.cmake-3-22-1
  ]);
  gradle = gradle_9_4_1;
  appPackage = buildGradlePackage rec {
    pname = "droidvm";
    inherit version src gradle;
    sourceRoot = "${src.name}";
    lockFile = mergeLock [ ./gradle.lock ];
    overrides = overrides-fromsrc;
    buildJdk = jdk21_headless;
    patches = [ ./build-sdk.patch ];
    gradleBuildFlags = ":app:assembleRelease";

    postPatch = ''
      rm -rf app/src/main/cpp/jsoncpp app/src/main/cpp/udisasm \
        app/src/main/cpp/libvncserver app/src/main/assets/prebuilts
      mkdir -p app/src/main/cpp/jsoncpp app/src/main/cpp/udisasm \
        app/src/main/cpp/libvncserver app/src/main/assets/prebuilts
      cp -R ${jsoncpp}/. app/src/main/cpp/jsoncpp/
      cp -R ${udisasm}/. app/src/main/cpp/udisasm/
      cp -R ${libvncserver}/. app/src/main/cpp/libvncserver/
      cp -R ${prebuilts}/. app/src/main/assets/prebuilts/

      # Upstream: https://github.com/Droid-VM/DroidVM, DroidVM, GPL-3.0-only.
      # Its build script derives version code from Git history.
      # Preserve the v0.0.6 upstream count without fetching unrelated history.
      substituteInPlace app/build.gradle.kts \
        --replace-fail \
          'val gitCommitCount = runGit("rev-list", "--count", "HEAD").toInt()' \
          'val gitCommitCount = System.getenv("DROIDVM_COMMIT_COUNT")?.toInt() ?: runGit("rev-list", "--count", "HEAD").toInt()'

      git init -q
      git add -A
      GIT_AUTHOR_DATE="2026-01-01T00:00:00Z" \
        GIT_COMMITTER_DATE="2026-01-01T00:00:00Z" \
        git -c user.name=Build -c user.email=build@example.invalid commit -qm "DroidVM ${version} source"
      git tag "${version}"
    '';

    nativeBuildInputs = [
      androidSdk
      gradle
      git
      jdk21_headless
      jdk25_headless
      writableTmpDirAsHomeHook
    ];
    env = {
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/30.0.14904198";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
      DROIDVM_COMMIT_COUNT = "30";
    };
    gradleFlags = [
      "-Dorg.gradle.java.home=${jdk25_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk21_headless},${jdk25_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    ];
    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
    '';
    installPhase = ''
      runHook preInstall
      install -Dm644 app/build/outputs/apk/release/app-release-unsigned.apk "$out/droidvm.apk"
      runHook postInstall
    '';

    meta = with lib; {
      sourceProvenance = with sourceTypes; [ fromSource ];
      description = "Android virtual machine manager built from source";
      homepage = "https://github.com/Droid-VM/DroidVM";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "droidvm.apk";
  signScriptName = "sign-droidvm";
  fdroid = {
    appId = "cn.classfun.droidvm";
    metadataYml = ''
      Categories:
        - System
      License: GPL-3.0-only
      SourceCode: https://github.com/Droid-VM/DroidVM
      IssueTracker: https://github.com/Droid-VM/DroidVM/issues
      AutoName: DroidVM
      Summary: Virtual machine manager for Android
      Description: |-
        DroidVM manages virtual machines using KVM, Gunyah, and GenieZone.
        Built from the v${version} source and pinned native source submodules.
    '';
  };
}
