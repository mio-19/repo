{
  mk-apk-package,
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  flutter344,
  jdk17_headless,
  python3,
  gradle_8_13,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
  shaderc,
}:
let
  flutterApkHelpers = ../_shared/flutter-apk-helpers.sh;
  mkFlutterSdkSourceBuilder = import ../_shared/mk-flutter-sdk-source-builder.nix;

  # local_plugins/llama_flutter_android builds llama.cpp with the Vulkan
  # backend. Its CMakeLists fetches these headers over the network and needs a
  # glslc new enough for cooperative-matrix shaders (the NDK's shaderc 2022.x
  # cannot compile them). Both are provided offline via
  # FETCHCONTENT_SOURCE_DIR_* and a VULKAN_SDK-shaped glslc wrapper below.
  vulkanHeaders = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "Vulkan-Headers";
    tag = "v1.4.363";
    hash = "sha256-E/SBlMW1oUeUT0MtWzQp0k+OSZLc9ho7g+1oTd7z7+Y=";
  };

  spirvHeaders = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-Headers";
    tag = "vulkan-sdk-1.4.363.0";
    hash = "sha256-PTD3GxQnENDngl6bf9YCmCVmvRgdBZczBosFCOCYEXU=";
  };

  vulkanSdk = runCommand "vulkan-sdk-glslc" { } ''
    mkdir -p $out/bin
    ln -s ${lib.getBin shaderc}/bin/glslc $out/bin/glslc
  '';

  # stable-diffusion.cpp is a git submodule of the source tree that is empty in
  # the GitHub tarball. Fetch the exact pinned commit so the sd_flutter_android
  # plugin can build its Vulkan/DirectML backends offline.
  stableDiffusionCpp = fetchFromGitHub {
    owner = "leejet";
    repo = "stable-diffusion.cpp";
    rev = "90e87bc846f17059771efb8aaa31e9ef0cab6f78";
    hash = "sha256-T7e5I+jD1FJ9/6ISdzOi+AtvAGD4FuQZrUx0z1ddRHA=";
  };

  # ggml is a submodule of stable-diffusion.cpp; the tarball leaves it empty too.
  ggmlForStableDiffusion = fetchFromGitHub {
    owner = "ggml-org";
    repo = "ggml";
    rev = "404fcb9d7c96989569e68c9e7881ee3465a05c50";
    hash = "sha256-3fZzbJW9p+00meg53HF/seVPAsETmpjn1u0q9l2Di2c=";
  };

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-34
        s.platforms-android-35
        s.platforms-android-36
        s.build-tools-34-0-0
        s.build-tools-35-0-0
        s.build-tools-36-0-0
        s.ndk-27-0-12077973
        s.ndk-28-2-13676358
        s.cmake-3-22-1
      ]);

      gradle = gradle_8_13;
      androidSdkRoot = "${androidSdk}/share/android-sdk";
      aapt2 = "${androidSdkRoot}/build-tools/36.0.0/aapt2";
      pythonWithYaml = python3.withPackages (ps: [ ps.pyyaml ]);
    in
    buildDartApplication.override { dart = flutter344; } (finalAttrs: {
      pname = "privatelm";
      version = "1.0.7+7";

      src = fetchFromGitHub {
        owner = "orailnoor";
        repo = "cross-platform-llm-client";
        rev = "main";
        hash = "sha256-pSAfmWUhu0gU0ueFaCx976hBNltr2+tX70hmoIMwRcs=";
      };

      pubspecLock = lib.importJSON ./pubspec.lock.json;
      gitHashes = { };

      sdkSourceBuilders = {
        flutter = mkFlutterSdkSourceBuilder {
          inherit runCommand;
          flutter = flutter344;
        };
      };

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        attrPath = "apk_privatelm";
        pkg = finalAttrs.finalPackage;
        data = ./privatelm_deps.json;
        silent = false;
        useBwrap = false;
      };

      gradleUpdateScript = ''
        runHook preBuild
        runHook preGradleUpdate
        flutter build apk --release --no-pub --android-skip-build-dependency-validation
        runHook postGradleUpdate
      '';

      dontDartBuild = true;
      dontDartInstall = true;

      nativeBuildInputs = [
        gradle
        jdk17_headless
        python3
        writableTmpDirAsHomeHook
        git
      ];

      env = {
        JAVA_HOME = jdk17_headless.passthru.home;
        ANDROID_HOME = androidSdkRoot;
        ANDROID_SDK_ROOT = androidSdkRoot;
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = aapt2;
        NIX_VULKAN_HEADERS = vulkanHeaders;
        NIX_SPIRV_HEADERS = spirvHeaders;
        VULKAN_SDK = vulkanSdk;
      };

      sdkSetupScript = ''
        flutter config --no-analytics >/dev/null 2>&1 || true
      '';

      gradleFlags = [
        "--project-dir"
        "android"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless.passthru.home}"
        "-Dandroid.aapt2FromMavenOverride=${aapt2}"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
      ];

      # Patch the plugin's CMakeLists so find_program falls back to PATH
      # (the gcc/g++ wrappers are already on PATH) rather than hardcoding
      # /usr/bin, and so the modern glslc is always used.
      postPatch = ''
        . ${flutterApkHelpers}
        setup_writable_flutter_sdk ${flutter344}
        setup_pinned_gradlew ${gradle}/bin/gradle

        # The llama.cpp Vulkan shaders-gen is a host-side CMake build whose
        # toolchain only looks in /usr/bin for compilers and in
        # /opt/homebrew/bin /usr/local/bin for glslc. Neither exist in the Nix
        # sandbox; those same substitutions are also done at build time via
        # the llama-vulkan-offline.patch applied in preBuild.
        substituteInPlace local_plugins/llama_flutter_android/android/CMakeLists.txt \
          --replace-fail 'PATHS /usr/bin /usr/local/bin NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)' ')'

        substituteInPlace local_plugins/llama_flutter_android/android/CMakeLists.txt \
          --replace-fail 'PATHS /opt/homebrew/bin /usr/local/bin ENV VULKAN_SDK' 'PATHS ${vulkanSdk}'

        # Flutter derives its version from git when no version file exists.
        git init -q || true
        git config user.email "nix@nix" || true
        git config user.name "nix" || true
        git add -A || true
        git -c commit.gpgsign=false commit -q -m "nix" --no-verify || true
        if [ -d flutter-sdk ] && [ ! -d flutter-sdk/.git ]; then
          ( cd flutter-sdk && git init -q && git config user.email "nix@nix" \
            && git config user.name "nix" && git add -A \
            && git -c commit.gpgsign=false commit -q -m "nix" --no-verify ) || true
        fi
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        {
          echo "sdk.dir=${androidSdkRoot}"
          echo "cmake.dir=${androidSdkRoot}/cmake/3.22.1"
          # Do not set ndk.dir in local.properties — let AGP pick per-module.
          echo "flutter.sdk=$PWD/flutter-sdk"
          echo "flutter.versionName=1.0.7"
          echo "flutter.versionCode=7"
        } > android/local.properties
      '';

      preBuild = ''
        export HOME="$(mktemp -d)"

        . ${flutterApkHelpers}

        printf '%s\n' \
          'storePassword=android' \
          'keyPassword=android' \
          'keyAlias=androiddebugkey' \
          'storeFile=../debug.keystore' > android/key.properties

        rm -f android/debug.keystore
        keytool -genkeypair -noprompt \
          -keystore android/debug.keystore \
          -storepass android \
          -keypass android \
          -alias androiddebugkey \
          -keyalg RSA \
          -keysize 2048 \
          -validity 10000 \
          -dname "CN=Android Debug,O=Android,C=US"

        GRADLE_OPTS="''${GRADLE_OPTS:-}"

        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.auto-download=false"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.paths=${jdk17_headless.passthru.home}"
        GRADLE_OPTS="$GRADLE_OPTS -Dandroid.aapt2FromMavenOverride=${aapt2}"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
        append_mitm_gradle_opts
        export FLUTTER_ROOT="$PWD/flutter-sdk"

        mkdir -p .dart-patched
        declare -A patched_pkg_dirs

        ${pythonWithYaml}/bin/python3 ${../_shared/generate-flutter-plugins.py}

        # Flutter plugins live in the Nix store; CMake/AGP write under plugin
        # android/ trees (e.g. the jni plugin's .cxx/), so clone them to a
        # writable dir and remap package_config / plugin metadata.
        while IFS= read -r plugin_dir; do
          [ -n "$plugin_dir" ] || continue
          ensure_writable_dart_package "$plugin_dir" >/dev/null
        done < <(${python3}/bin/python3 - <<'PY'
        import json

        with open(".flutter-plugins-dependencies") as f:
            data = json.load(f)
        for plugin in data.get("plugins", {}).get("android", []):
            path = plugin.get("path", "")
            if path and plugin.get("native_build"):
                print(path)
        PY
        )

        # The llama.cpp Vulkan headers + glslc selection are provided offline
        # via the llama-vulkan-offline.patch (FETCHCONTENT_SOURCE_DIR_* and
        # Vulkan_GLSLC_EXECUTABLE). Apply it to both the writable clone and the
        # source-local copy so the patch also survives ensure_writable_dart_package.
        for dir in \
          .dart-patched/llama_flutter_android \
          local_plugins/llama_flutter_android; do
          if [ -f "$dir/android/CMakeLists.txt" ] && \
             ! grep -q "NIX_VULKAN_HEADERS" "$dir/android/CMakeLists.txt"; then
            patch -p1 -d "$dir" < ${./llama-vulkan-offline.patch}
          fi
        done

        # stable-diffusion.cpp and its ggml submodule are git submodules left
        # empty in the GitHub tarball. Populate them in both the writable clone
        # and the source-local copy when building the sd_flutter_android plugin.
        # The plugin's CMakeLists expects stable-diffusion.cpp under
        # android/src/main/cpp/stable-diffusion.cpp.
        for dir in \
          .dart-patched/sd_flutter_android \
          local_plugins/sd_flutter_android; do
          if [ -d "$dir" ] && [ ! -f "$dir/android/src/main/cpp/stable-diffusion.cpp/CMakeLists.txt" ]; then
            mkdir -p "$dir/android/src/main/cpp"
            cp -a --no-preserve=mode ${stableDiffusionCpp}/. "$dir/android/src/main/cpp/stable-diffusion.cpp"
            mkdir -p "$dir/android/src/main/cpp/stable-diffusion.cpp/ggml"
            cp -a --no-preserve=mode ${ggmlForStableDiffusion}/. "$dir/android/src/main/cpp/stable-diffusion.cpp/ggml"
          fi
        done
      '';

      buildPhase = ''
        runHook preBuild
        flutter build apk --release --no-pub --android-skip-build-dependency-validation
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 build/app/outputs/flutter-apk/app-release.apk \
          "$out/privatelm.apk"
        runHook postInstall
      '';

      meta = with lib; {
        sourceProvenance = with sourceTypes; [ fromSource ];
        description = "PrivateLM - AI Chat client built from source";
        homepage = "https://github.com/orailnoor/cross-platform-llm-client";
        license = licenses.mit;
        platforms = platforms.unix;
      };
    });

in
mk-apk-package {
  inherit appPackage;
  mainApk = "privatelm.apk";
  signScriptName = "sign-privatelm";
  fdroid = {
    appId = "com.orailnoor.privatelm";
    metadataYml = ''
      Categories:
        - Internet
      License: MIT
      SourceCode: https://github.com/orailnoor/cross-platform-llm-client
      IssueTracker: https://github.com/orailnoor/cross-platform-llm-client/issues
      AutoName: PrivateLM
      Summary: AI Chat client with local and cloud LLM support
      Description: |-
        PrivateLM is a cross-platform AI chat client supporting local on-device
        LLM inference and cloud APIs.
        This package is built from source.
    '';
  };
}
