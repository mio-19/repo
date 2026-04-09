{
  mk-apk-package,
  lib,
  jdk21_headless,
  gradle-packages,
  stdenv,
  fetchgit,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
  bash,
  gnumake,
  cmake,
  ninja,
  pkg-config,
  optipng,
  icu,
  boost,
  qt6,
  python3,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-0-0
        s.ndk-28-2-13676358
        s.cmake-3-31-6
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.14.3";
          hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
          defaultJava = jdk21_headless;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "comaps";
      version = "2026.04.07-8";

      src = fetchgit {
        url = "https://codeberg.org/comaps/comaps.git";
        tag = "v${finalAttrs.version}";
        fetchSubmodules = true;
        hash = "sha256-FV73hkvAIivwHld7S6yEtAhNOwdnhGmAoN1m3JUB6m0=";
      };

      sourceRoot = "${finalAttrs.src.name}/android";
      dontFixup = true;
      dontUseCmakeConfigure = true;

      gradleBuildTask = ":app:assembleFdroidRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./comaps_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21_headless
        apksigner
        writableTmpDirAsHomeHook
        git
        bash
        gnumake
        cmake
        ninja
        pkg-config
        optipng
        icu
        qt6.qtbase
        qt6.qtsvg
        qt6.qtpositioning
      ];
      dontWrapQtApps = true;

      env = {
        JAVA_HOME = jdk21_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
        PYTHON = python3;
      };

      # CoMaps CMake requires python protobuf >=3.20 and <4.0.
      # Nixpkgs default protobuf is 7.x, so provide a compatible interpreter.
      prePatch = ''
        export PATH="${(python3.withPackages (ps: [ ps.protobuf4 ]))}/bin:$PATH"
        substituteInPlace ../CMakeLists.txt \
          --replace-fail 'if(PROTOBUF_VERSION VERSION_LESS "3.20.0" OR PROTOBUF_VERSION VERSION_GREATER_EQUAL "4.0.0")' \
            'if(PROTOBUF_VERSION VERSION_LESS "3.20.0" OR PROTOBUF_VERSION VERSION_GREATER_EQUAL "5.0.0")' \
          --replace-fail 'version (>=3.20, <4.0) is required' \
            'version (>=3.20, <5.0) is required' \
          --replace-fail 'found (>=3.20, <4.0)' \
            'found (>=3.20, <5.0)'
      '';

      postUnpack = ''
        chmod -R u+w .
      '';

      preConfigure = ''
        if [ -n "''${MITM_CACHE_ADDRESS:-}" ]; then
          export http_proxy="http://$MITM_CACHE_ADDRESS"
          export https_proxy="http://$MITM_CACHE_ADDRESS"
          export HTTP_PROXY="$http_proxy"
          export HTTPS_PROXY="$https_proxy"
          export GRADLE_OPTS="-Dhttp.proxyHost=$MITM_CACHE_HOST -Dhttp.proxyPort=$MITM_CACHE_PORT -Dhttps.proxyHost=$MITM_CACHE_HOST -Dhttps.proxyPort=$MITM_CACHE_PORT"
        fi
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        echo "ndk.dir=${androidSdk}/share/android-sdk/ndk/28.2.13676358" >> local.properties
        echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.31.6" >> local.properties
      '';

      preBuild = ''
        pushd ..
        export PATH="${(python3.withPackages (ps: [ ps.protobuf4 ]))}/bin:$PATH"
        rm -rf 3party/boost/boost
        ln -s ${boost.dev}/include/boost 3party/boost/boost
        ${python3}/bin/python3 ./tools/python/categories/json_to_txt.py data/categories-strings data/categories.txt
        ${python3}/bin/python3 ./tools/python/generate_desktop_ui_strings.py
        bash ./tools/unix/generate_drules.sh
        for required in \
          data/classificator.txt \
          data/types.txt \
          data/visibility.txt \
          data/colors.txt \
          data/patterns.txt \
          data/drules_proto_default_dark.bin \
          data/drules_proto_default_light.bin \
          data/drules_proto_outdoors_dark.bin \
          data/drules_proto_outdoors_light.bin \
          data/drules_proto_vehicle_dark.bin \
          data/drules_proto_vehicle_light.bin \
          data/categories.txt \
          data/countries.txt
        do
          test -f "$required"
        done
        popd
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
        "--no-daemon"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Parm64"
      ];

      installPhase = ''
        runHook preInstall
        apk_dir="app/build/outputs/apk/fdroid/release"
        apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
        test -n "$apk_name"
        apk_path="$apk_dir/$apk_name"
        test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/comaps.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "CoMaps offline maps app (F-Droid flavor, source-built)";
        homepage = "https://codeberg.org/comaps/comaps";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "comaps.apk";
  signScriptName = "sign-comaps";
  fdroid = {
    appId = "app.comaps.fdroid";
    metadataYml = ''
      Categories:
        - Navigation
      License: Apache-2.0
      WebSite: https://www.comaps.app/
      SourceCode: https://codeberg.org/comaps/comaps
      IssueTracker: https://codeberg.org/comaps/comaps/issues
      Translation: https://translate.codeberg.org/projects/comaps/
      Changelog: https://codeberg.org/comaps/comaps/releases
      Donate: https://www.comaps.app/donate/
      Liberapay: CoMaps
      OpenCollective: comaps
      AutoName: CoMaps
      Summary: Offline maps navigation app focused on privacy
      Description: |-
        CoMaps is a community-led maps app based on OpenStreetMap.
        This package builds the F-Droid flavor from source and follows
        the upstream/F-Droid build process.
    '';
  };
}
