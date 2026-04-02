{
  mk-apk-package,
  lib,
  stdenv,
  stdenvNoCC,
  fetchgit,
  fetchurl,
  jdk17_headless,
  gradle-packages,
  androidSdkBuilder,
  patchelf,
  qt5,
  apksigner,
  p7zip,
  writableTmpDirAsHomeHook,
  fetchpatch,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-31
    s.build-tools-31-0-0
    # Tried NDK 27.3.13750724 here, but the build then failed later in
    # androiddeployqt packaging with no Qt Android platform plugin included,
    # so this remains on the baseline NDK until that Qt packaging issue is fixed.
    s.ndk-21-4-7075529
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "7.2";
      hash = "sha256-9YFwmpw16cuS4W9YXSxLyZsrGl+F0rrb09xr/1nh5t0=";
      defaultJava = jdk17_headless;
    }).wrapped;

  version = "unstable-2026-01-24";
  rev = "556ca6740ce1c2171db6bd028de6690bc7094453";

  src = fetchgit {
    url = "https://github.com/nspire-emus/firebird.git";
    inherit rev;
    fetchSubmodules = true;
    hash = "sha256-JOKz9nKPxP/rE1JQLY6VR+PduGEM0sXBBwT5Mk65Na0=";
  };

  qtArchiveBaseUrl = "https://download.qt.io/online/qtsdkrepository/linux_x64/android/qt5_5152/qt.qt5.5152.android";

  qtAndroidArchives = [
    (fetchurl {
      url = "${qtArchiveBaseUrl}/5.15.2-0-202011130628qtbase-Linux-RHEL_7_6-Clang-Android-Android_ANY-Multi.7z";
      sha256 = "1ljnsaz24hbxmq6a0fdx796gqz0323gq9li6v5j9lysmdn6dv7vb";
    })
    (fetchurl {
      url = "${qtArchiveBaseUrl}/5.15.2-0-202011130628qtdeclarative-Linux-RHEL_7_6-Clang-Android-Android_ANY-Multi.7z";
      sha256 = "10mzq82k27di797s7lpmsb82jrhm0dvkyx8dsy0kqpxy2vihay6p";
    })
    (fetchurl {
      url = "${qtArchiveBaseUrl}/5.15.2-0-202011130628qtquickcontrols-Linux-RHEL_7_6-Clang-Android-Android_ANY-Multi.7z";
      sha256 = "1gjzvqgq81gsvr4xfq4fa689w3cg0qnmr5n0hblz3754m9zah6w6";
    })
    (fetchurl {
      url = "${qtArchiveBaseUrl}/5.15.2-0-202011130628qtandroidextras-Linux-RHEL_7_6-Clang-Android-Android_ANY-Multi.7z";
      sha256 = "1fyq6azm3gc8wkps609qs2b94r7jcf4cv0dw9yvnbvllgnvm4vd2";
    })
  ];

  qtAndroidPrefix = stdenvNoCC.mkDerivation {
    pname = "qt5-android-firebird-prefix";
    version = "5.15.2";
    srcs = qtAndroidArchives;
    nativeBuildInputs = [ p7zip ];
    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      for archive in $srcs; do
        7z x -y "$archive" >/dev/null
      done

      cp -a 5.15.2/android/. "$out"/

      mkdir -p "$out/src/android" "$out/src/3rdparty"
      cp -as ${qt5.srcs.qtbase.src}/src/android/templates "$out/src/android/templates"
      cp -as ${qt5.srcs.qtbase.src}/src/android/java "$out/src/android/java"
      cp -as ${qt5.srcs.qtbase.src}/src/3rdparty/gradle "$out/src/3rdparty/gradle"

      substituteInPlace "$out/mkspecs/qconfig.pri" \
        --replace-fail "QT_EDITION = Enterprise" "QT_EDITION = OpenSource" \
        --replace-fail "QT_LICHECK = licheck64" "QT_LICHECK ="

      cat > "$out/src/3rdparty/gradle/gradlew" <<EOF
      #!${stdenv.shell}
      exec ${gradle}/bin/gradle "\$@"
      EOF
      chmod +x "$out/src/3rdparty/gradle/gradlew"

      host_rpath="$out/lib:${stdenv.cc.cc.lib}/lib"
      for bin in "$out"/bin/*; do
        if file "$bin" | grep -q 'ELF 64-bit LSB executable, x86-64'; then
          ${patchelf}/bin/patchelf \
            --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" \
            --set-rpath "$host_rpath" \
            "$bin"
        fi
      done

      runHook postInstall
    '';
  };

  generateAndroidProject = ''
    if [ -f android-firebird-emu-deployment-settings.json ]; then
      :
    elif [ -d build ]; then
      cd build
    elif [ -d "$sourceRoot/build" ]; then
      cd "$sourceRoot/build"
    elif [ -d "$NIX_BUILD_TOP/$sourceRoot/build" ]; then
      cd "$NIX_BUILD_TOP/$sourceRoot/build"
    else
      echo "Could not locate generated Firebird build directory" >&2
      exit 1
    fi

    make -j"$NIX_BUILD_CORES" apk_install_target

    ${qtAndroidPrefix}/bin/androiddeployqt \
      --input android-firebird-emu-deployment-settings.json \
      --output android-build \
      --apk firebird-emu.apk \
      --android-platform android-31 \
      --gradle \
      --verbose
  '';

  appPackage = stdenv.mkDerivation (finalAttrs: {
    pname = "firebird";
    inherit version src;

    gradleBuildTask = "assembleDebug";
    gradleUpdateTask = finalAttrs.gradleBuildTask;

    gradleUpdateScript = ''
      runHook preBuild
      ${generateAndroidProject}
      cd android-build
      gradle ${finalAttrs.gradleUpdateTask}
    '';

    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./firebird_deps.json;
      silent = false;
      useBwrap = false;
    };

    patches = [
      /*
        (fetchpatch {
          name = "I make a svg keypad，can i merge it to this project";
          url = "https://github.com/nspire-emus/firebird/pull/305.diff";
          hash = "sha256-mZUDSZE2hPR78ZLzRpKahsxhmwOenErQaeG7obreKG4=";
        })
      */
      (fetchpatch {
        name = "[Mobile UI] Introduce separate keypad fill modes (#297)";
        url = "https://github.com/nspire-emus/firebird/pull/298.diff";
        hash = "sha256-pJf3nUJ3BbbCOx+yvUtchfzts0dbCMaa3essTDcbB4o=";
      })
      (fetchpatch {
        name = "[Android] Simple haptic feedback";
        url = "https://github.com/nspire-emus/firebird/pull/362.diff";
        hash = "sha256-ls/cC0dVetjYrMAi1HHGZBiz4b9R4kk+98ak6v2c6kU=";
      })
    ];

    nativeBuildInputs = [
      gradle
      jdk17_headless
      apksigner
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = jdk17_headless;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/21.4.7075529";
      ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/21.4.7075529";
      ANDROID_NDK_HOST = "linux-x86_64";
      ANDROID_NDK_PLATFORM = "android-21";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/31.0.0/aapt2";
    };

    preConfigure = ''
      export HOME="$TMPDIR/home"
      export ANDROID_USER_HOME="$HOME/.android"
      export GRADLE_USER_HOME="$TMPDIR/gradle-home"
      mkdir -p "$HOME" "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"

      toolchain_bin="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin"
      mkdir -p "$TMPDIR/toolchain-bin"
      cat > "$TMPDIR/toolchain-bin/clang" <<EOF
      #!${stdenv.shell}
      exec "$toolchain_bin/aarch64-linux-android21-clang" "\$@"
      EOF
      cat > "$TMPDIR/toolchain-bin/clang++" <<EOF
      #!${stdenv.shell}
      exec "$toolchain_bin/aarch64-linux-android21-clang++" "\$@"
      EOF
      chmod +x "$TMPDIR/toolchain-bin/clang" "$TMPDIR/toolchain-bin/clang++"

      export PATH="$TMPDIR/toolchain-bin:$toolchain_bin:${qtAndroidPrefix}/bin:$PATH"
      export QMAKEPATH="${qtAndroidPrefix}''${QMAKEPATH:+:$QMAKEPATH}"
      export QMAKEMODULES="${qtAndroidPrefix}/mkspecs''${QMAKEMODULES:+:$QMAKEMODULES}"
      export QML_IMPORT_PATH="${qtAndroidPrefix}/qml"

      mkdir build
      cd build
      ${qtAndroidPrefix}/bin/qmake ../firebird.pro -spec android-clang ANDROID_ABIS=arm64-v8a

      qt_prefix="$(grep -m1 '"qt": ' android-firebird-emu-deployment-settings.json | cut -d '"' -f 4)"
      substituteInPlace android-firebird-emu-deployment-settings.json \
        --replace-fail "\"qt\": \"$qt_prefix\"" "\"qt\": \"${qtAndroidPrefix}\""
    '';

    preBuild = ''
      GRADLE_OPTS="''${GRADLE_OPTS:-}"
      GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.auto-download=false"
      GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.paths=${jdk17_headless}"
      GRADLE_OPTS="$GRADLE_OPTS -Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/31.0.0/aapt2"
      GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/31.0.0/aapt2"
      if [[ -n "''${MITM_CACHE_KEYSTORE:-}" ]]; then
        GRADLE_OPTS="$GRADLE_OPTS -Dhttp.proxyHost=$MITM_CACHE_HOST"
        GRADLE_OPTS="$GRADLE_OPTS -Dhttp.proxyPort=$MITM_CACHE_PORT"
        GRADLE_OPTS="$GRADLE_OPTS -Dhttps.proxyHost=$MITM_CACHE_HOST"
        GRADLE_OPTS="$GRADLE_OPTS -Dhttps.proxyPort=$MITM_CACHE_PORT"
        GRADLE_OPTS="$GRADLE_OPTS -Djavax.net.ssl.trustStore=$MITM_CACHE_KEYSTORE"
        GRADLE_OPTS="$GRADLE_OPTS -Djavax.net.ssl.trustStorePassword=$MITM_CACHE_KS_PWD"
      fi
      export GRADLE_OPTS
    '';

    buildPhase = ''
      runHook preBuild

      ${generateAndroidProject}

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      apk_path="$(find "$NIX_BUILD_TOP/$sourceRoot/build/android-build" -type f -name '*.apk' | head -n 1)"
      test -n "$apk_path"
      install -Dm644 "$apk_path" "$out/firebird.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "TI-Nspire emulator for Android";
      homepage = "https://github.com/nspire-emus/firebird";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
    };
  });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "firebird.apk";
  signScriptName = "sign-firebird";
  fdroid = {
    appId = "org.firebird.emu";
    metadataYml = ''
      Categories:
        - Education
      License: GPL-3.0-only
      SourceCode: https://github.com/nspire-emus/firebird
      IssueTracker: https://github.com/nspire-emus/firebird/issues
      Changelog: https://github.com/nspire-emus/firebird/commits/master
      AutoName: Firebird Emu
      Summary: TI-Nspire emulator
      Description: |-
        Firebird Emu is a community TI-Nspire emulator.

        This package builds the Android app from upstream source using
        the Qt-for-Android toolchain under Nix.
    '';
  };
}
