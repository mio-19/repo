{
  mk-apk-package,
  lib,
  jdk21_headless,
  gradle_8_13,
  stdenv,
  fetchFromGitHub,
  writeShellScript,
  _experimental-update-script-combinators,
  nix-update-script,

  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  gettext,
}:
let
  appPackage =
    let
      version = "5.15.2";

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-34
        s.platforms-android-35
        s.build-tools-34-0-0
        s.build-tools-35-0-0
        s.ndk-29-0-14206865
        s.cmake-3-22-1
      ]);

      gradle = gradle_8_13;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "luanti";
      inherit version;

      src = fetchFromGitHub {
        owner = "luanti-org";
        repo = "luanti";
        tag = version;
        hash = "sha256-E7YkUFuDvEuJpmn7ReasKZnQHucl6YbTk8InUtzTi9U=";
      };

      sourceRoot = "${finalAttrs.src.name}/android";
      dontFixup = true;

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        attrPath = "apk_luanti";
        pkg = finalAttrs.finalPackage;
        data = ./luanti_deps.json;
        silent = false;
        useBwrap = false;
      };

      passthru.updateScript =
        (_experimental-update-script-combinators.sequence [
          (nix-update-script {
            attrPath = "apk_luanti";
            extraArgs = [ "--flake" ];
          })
          {
            command = [
              "${writeShellScript "update-apk-luanti-gradle-deps" ''
                set -euo pipefail
                system="$(nix eval --impure --raw --expr builtins.currentSystem)"
                "$(nix build ".#legacyPackages.$system.apk_luanti.mitmCache.updateScript" --no-link --print-out-paths)"
              ''}"
            ];
            supportedFeatures = [ ];
          }
        ])
        // {
          attrPath = "apk_luanti";
        };

      nativeBuildInputs = [
        gradle
        jdk21_headless

        writableTmpDirAsHomeHook
        gettext
      ];

      env = {
        JAVA_HOME = jdk21_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/29.0.14206865";
        ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/29.0.14206865";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };

      postUnpack = ''
        chmod -R u+w .
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        chmod -R u+w "$PWD/.."
        cat > local.properties <<EOF
        sdk.dir=${androidSdk}/share/android-sdk
        ndk.dir=${androidSdk}/share/android-sdk/ndk/29.0.14206865
        EOF
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Pandroid.injected.build.abi=arm64-v8a"
        "-Pandroid.injected.testOnly=false"
      ];

      installPhase = ''
        runHook preInstall
        apk_path=""
        apk_dir="app/build/outputs/apk/release"
        metadata="$apk_dir/output-metadata.json"
        if [ -f "$metadata" ]; then
          apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$metadata" | head -n 1)"
          if [ -n "$apk_name" ] && [ -f "$apk_dir/$apk_name" ]; then
            apk_path="$apk_dir/$apk_name"
          fi
        fi

        if [ -z "$apk_path" ]; then
          apk_path="$(
            find . -type f -name '*release*.apk' \
              ! -name '*androidTest*' \
              ! -name '*test*.apk' \
              ! -name '*debug*' \
              | head -n 1
          )"
        fi
        test -n "$apk_path"
        install -Dm644 "$apk_path" "$out/luanti.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Luanti Android client built from source";
        homepage = "https://github.com/luanti-org/luanti";
        license = licenses.lgpl21Plus;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "luanti.apk";
  signScriptName = "sign-luanti";
  fdroid = {
    appId = "net.minetest.minetest";
    metadataYml = ''
      Categories:
        - Games
      License: LGPL-2.1-or-later
      SourceCode: https://github.com/luanti-org/luanti
      IssueTracker: https://github.com/luanti-org/luanti/issues
      AutoName: Luanti
      Summary: Open-source voxel game engine and client
      Description: |-
        Luanti (formerly Minetest) is a free and open-source voxel game
        engine with modding and game creation support.
        This package is built from source.
    '';
  };
}
