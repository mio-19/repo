{
  mk-apk-package,
  lib,
  path,
  symlinkJoin,
  runCommand,
  patchelf,
  jdk21_headless,
  jdk25_headless,
  gradle_9_7_1,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  writeShellScriptBin,
  rustPlatform,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage = stdenv.mkDerivation (
    finalAttrs0:
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-37-0
        s.build-tools-36-0-0
      ]);
      androidSdkRoot = "${androidSdk}/share/android-sdk";
      aapt2 = "${androidSdkRoot}/build-tools/36.0.0/aapt2";

      gradle = gradle_9_7_1;

      androidCrossConfig = {
        config.allowUnfree = true;
        localSystem = stdenv.buildPlatform.system;
      };

      mkAndroidPkgs =
        {
          config,
          rustTarget,
        }:
        import path (
          androidCrossConfig
          // {
            crossSystem = {
              inherit config;
              androidSdkVersion = "35";
              androidNdkVersion = "29";
              useAndroidPrebuilt = true;
              rust.rustcTarget = rustTarget;
            };
          }
        );

      aarch64AndroidPkgs = mkAndroidPkgs {
        config = "aarch64-unknown-linux-android";
        rustTarget = "aarch64-linux-android";
      };

      x86_64AndroidPkgs = mkAndroidPkgs {
        config = "x86_64-unknown-linux-android";
        rustTarget = "x86_64-linux-android";
      };

      rustDeps = rustPlatform.fetchCargoVendor {
        pname = "koiterminal-rust-deps";
        inherit (finalAttrs0) version src;
        cargoRoot = "AndroidStudioProject/rust";
        hash = "sha256-y72v2yeqNIKwprxI5eK5G09sdgzcCfzYvJVPfdILbAA=";
      };

      mkForwarderJniLib =
        {
          crossPkgs,
          rustTarget,
          abi,
        }:
        crossPkgs.rustPlatform.buildRustPackage {
          pname = "forwarder-host-jni-${abi}";
          inherit (finalAttrs0) version src;

          buildAndTestSubdir = "AndroidStudioProject/rust";
          cargoRoot = "AndroidStudioProject/rust";
          cargoDeps = rustDeps;

          CARGO_BUILD_TARGET = rustTarget;
          doCheck = false;

          installPhase = ''
            runHook preInstall
            mkdir -p "$out/${abi}"
            find target -name "libforwarder_host_jni.so" -exec cp {} "$out/${abi}/" \;
            runHook postInstall
          '';
        };

      forwarderJniLibs = symlinkJoin {
        name = "koiterminal-forwarder-jni-libs";
        paths = [
          (mkForwarderJniLib {
            crossPkgs = aarch64AndroidPkgs;
            rustTarget = "aarch64-linux-android";
            abi = "arm64-v8a";
          })
          (mkForwarderJniLib {
            crossPkgs = x86_64AndroidPkgs;
            rustTarget = "x86_64-linux-android";
            abi = "x86_64";
          })
        ];
      };

      androidCustomJar = fetchurl {
        url = "https://github.com/outlawsanzhang/android-hidden-api/releases/download/37.0/android-37-custom.jar";
        hash = "sha256-HO07y5CZDVuefJGoqk/zqSJJdtWCpm5ggQ+EHdzVq7E=";
      };

      protocRaw = fetchurl {
        url = "https://repo.maven.apache.org/maven2/com/google/protobuf/protoc/4.33.0/protoc-4.33.0-linux-x86_64.exe";
        hash = "sha256-hV7KEg7atA7WEfKzpdolplTSL6THV94SjH4d+3DE1Oc=";
      };

      patchedProtoc = runCommand "protoc-4.33.0" { } ''
        cp ${protocRaw} $out
        chmod +x $out
      '';

      protocGenGrpcRaw = fetchurl {
        url = "https://repo.maven.apache.org/maven2/io/grpc/protoc-gen-grpc-java/1.84.0/protoc-gen-grpc-java-1.84.0-linux-x86_64.exe";
        hash = "sha256-kHwtTvwrrpshytp1wxs284IeFbe+ljEeIUpr5lvNIKo=";
      };

      patchedProtocGenGrpc =
        runCommand "protoc-gen-grpc-java-1.84.0"
          {
            nativeBuildInputs = [ patchelf ];
          }
          ''
            cp ${protocGenGrpcRaw} $out
            chmod u+w $out
            patchelf --page-size 2097152 \
                     --set-interpreter $(cat ${stdenv.cc}/nix-support/dynamic-linker) \
                     --set-rpath ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]} \
                     $out
            chmod +x $out
          '';
    in
    {
      pname = "koiterminal";
      version = "2026091900-unstable-2026-10-14";

      src = fetchFromGitHub {
        owner = "outlawsanzhang";
        repo = "koiTerminal";
        rev = "12de8af46b5f1291017e0380c8123edf632e4ba8";
        hash = "sha256-VHpmBog2kVicniovUpTWdoNrxQ6obG/8C+pfCP2U4us=";
      };

      sourceRoot = "${finalAttrs0.src.name}/AndroidStudioProject";

      postUnpack = ''
        chmod -R u+w .
      '';

      postPatch = ''
        substituteInPlace settings.gradle.kts \
          --replace-fail 'id("org.gradle.toolchains.foojay-resolver-convention")' '// id("org.gradle.toolchains.foojay-resolver-convention")'
        substituteInPlace tools/build_fake_sdk.sh \
          --replace-fail '#!/bin/sh' '#!${stdenv.shell}'
        substituteInPlace app/build.gradle.kts \
          --replace-fail 'artifact = "com.google.protobuf:protoc:4.33.0"' 'path = "${patchedProtoc}"'
        substituteInPlace libs_debian_service/build.gradle.kts \
          --replace-fail 'artifact = "com.google.protobuf:protoc:4.33.0"' 'path = "${patchedProtoc}"' \
          --replace-fail 'artifact = "io.grpc:protoc-gen-grpc-java:1.84.0"' 'path = "${patchedProtocGenGrpc}"'
      '';

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs0.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs0) pname;
        pkg = finalAttrs0.finalPackage;
        data = ./koiterminal_deps.json;
        silent = false;
        useBwrap = false;
      };

      passthru.updateScript = writeShellScriptBin "update-koiterminal" ''
        set -euo pipefail
        system="$(nix eval --impure --raw --expr builtins.currentSystem)"
        "$(nix build ".#legacyPackages.$system.apk_koiterminal.mitmCache.updateScript" --no-link --print-out-paths)"
      '';

      nativeBuildInputs = [
        gradle
        jdk25_headless
        jdk21_headless
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk25_headless.passthru.home;
        ANDROID_HOME = androidSdkRoot;
        ANDROID_SDK_ROOT = androidSdkRoot;
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = aapt2;
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"

        bash ./tools/build_fake_sdk.sh "${androidSdkRoot}" "$TMPDIR/modified_sdk" "${androidCustomJar}"
        ln -s android-37.0 "$TMPDIR/modified_sdk/platforms/android-37"
        ln -s 36.0.0 "$TMPDIR/modified_sdk/build-tools/37.0.0"
        echo "sdk.dir=$TMPDIR/modified_sdk" > local.properties

        mkdir -p app/src/main/jniLibs
        cp -r ${forwarderJniLibs}/. app/src/main/jniLibs/
        chmod -R u+w app/src/main/jniLibs
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk25_headless.passthru.home},${jdk21_headless.passthru.home}"
        "-Dandroid.aapt2FromMavenOverride=${aapt2}"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(find app/build/outputs -name "*.apk" | head -n 1)"
        install -Dm644 "$apk_path" "$out/koiterminal.apk"
        runHook postInstall
      '';

      meta = with lib; {
        sourceProvenance = with sourceTypes; [ fromSource ];
        description = "koiTerminal – Virtual machine terminal application for Android";
        homepage = "https://github.com/outlawsanzhang/koiTerminal";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    }
  );
in
mk-apk-package {
  inherit appPackage;
  mainApk = "koiterminal.apk";
  signScriptName = "sign-koiterminal";
  fdroid = {
    appId = "com.android.virtualization.koiterminal.githubaction";
    metadataYml = ''
      Categories:
        - System
      License: Apache-2.0
      SourceCode: https://github.com/outlawsanzhang/koiTerminal
      IssueTracker: https://github.com/outlawsanzhang/koiTerminal/issues
      AutoName: koiTerminal
      Summary: Virtual machine terminal application
      Description: |-
        koiTerminal is a fork of the Linux Terminal app for Android (AVF),
        providing terminal access and virtual machine management.
        This package is built from source.
    '';
  };
}
