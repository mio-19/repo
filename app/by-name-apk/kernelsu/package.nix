{ callPackage, ... }:
let
  appPackage = callPackage (
    {
      lib,
      pkgs,
      jdk21,
      gradle-packages,
      stdenv,
      fetchFromGitHub,
      apksigner,
      writableTmpDirAsHomeHook,
      androidSdkBuilder,
    }:
    let
      version = "1.0.5";

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.build-tools-35-0-0
        s.ndk-28-0-13004108
        s.cmake-3-22-1
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.12.1";
          hash = "sha256-jZepeYT2y9K4X+TGCnQ0QKNHVEvxiBgEjmEfUojUbJQ=";
          defaultJava = jdk21;
        }).wrapped;

      kernelsuSrc = fetchFromGitHub {
        owner = "tiann";
        repo = "KernelSU";
        tag = "v${version}";
        hash = "sha256-UZADtLgR7F89fxVc+rxcM2A+67hm6uBSGlQ4oR/YtRA=";
      };

      androidCrossConfig = {
        config.allowUnfree = true;
        localSystem = pkgs.stdenv.buildPlatform.system;
      };

      aarch64AndroidPkgs = import pkgs.path (
        androidCrossConfig
        // {
          crossSystem = {
            config = "aarch64-unknown-linux-android";
            androidSdkVersion = "35";
            androidNdkVersion = "27";
            useAndroidPrebuilt = true;
            rust.rustcTarget = "aarch64-linux-android";
          };
        }
      );

      x86_64AndroidPkgs = import pkgs.path (
        androidCrossConfig
        // {
          crossSystem = {
            config = "x86_64-unknown-linux-android";
            androidSdkVersion = "35";
            androidNdkVersion = "27";
            useAndroidPrebuilt = true;
            rust.rustcTarget = "x86_64-linux-android";
          };
        }
      );

      mkKsud =
        {
          crossPkgs,
          rustTarget,
        }:
        crossPkgs.rustPlatform.buildRustPackage {
          pname = "ksud";
          inherit version;

          src = kernelsuSrc;
          sourceRoot = "${kernelsuSrc.name}/userspace/ksud";

          cargoLock = {
            lockFile = "${kernelsuSrc}/userspace/ksud/Cargo.lock";
            outputHashes = {
              "hole-punch-0.0.4-alpha.0" = "sha256-Ye8jEhvDOxBsIzmLTF1oxSuIuFdcy0+sh5cCYbg+VZg=";
              "java-properties-2.0.0" = "sha256-fvekRqJI3Xwzo9z0Li36NFMIYnP5FMP8D9uVcK32soc=";
              "loopdev-0.5.0" = "sha256-div16sh2axal/SR3LRFLZxl3oOXBxzKA1hPq4ceJgjw=";
              "rustix-0.38.34" = "sha256-XzuiOKEvVee6nN8EltOgWrC4sUGhLKkm7pdPqDKuDWY=";
            };
          };

          doCheck = false;
          dontFixup = true;

          CARGO_BUILD_TARGET = rustTarget;
        };

      ksudArm64 = mkKsud {
        crossPkgs = aarch64AndroidPkgs;
        rustTarget = "aarch64-linux-android";
      };

      ksudX8664 = mkKsud {
        crossPkgs = x86_64AndroidPkgs;
        rustTarget = "x86_64-linux-android";
      };
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "kernelsu";
      inherit version;

      src = kernelsuSrc;

      sourceRoot = "source/manager";

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = "kernelsu_deps.json";
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/28.0.13004108";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };

      postPatch = ''
        substituteInPlace build.gradle.kts \
          --replace-fail \
          'val managerVersionCode by extra(getVersionCode())' \
          'val managerVersionCode by extra(12081)' \
          --replace-fail \
          'val managerVersionName by extra(getVersionName())' \
          'val managerVersionName by extra("v1.0.5")'

        install -Dm755 ${ksudArm64}/bin/ksud app/src/main/jniLibs/arm64-v8a/libksud.so
        install -Dm755 ${ksudX8664}/bin/ksud app/src/main/jniLibs/x86_64/libksud.so

        printf '\norg.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=1024m\n' >> gradle.properties
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags =
        let
          postfix = if stdenv.isDarwin then "" else "/lib/openjdk";
        in
        [
          "-xlintVitalRelease"
          "-Dorg.gradle.java.installations.auto-download=false"
          "-Dorg.gradle.java.installations.paths=${jdk21}${postfix}"
          "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
          "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        ];

      installPhase = ''
        runHook preInstall

        apk_path="$(find app/build/outputs/apk/release -name '*.apk' | head -n 1)"
        install -Dm644 "$apk_path" "$out/kernelsu.apk"

        runHook postInstall
      '';

      meta = with lib; {
        description = "KernelSU Manager app built from source";
        homepage = "https://github.com/tiann/KernelSU";
        license = licenses.gpl3Plus;
        platforms = platforms.unix;
      };
    })
  ) { };
in
callPackage ../../by-name/mk-apk-package/package.nix {
  inherit appPackage;
  mainApk = "kernelsu.apk";
  signScriptName = "sign-kernelsu";
  fdroid = {
    appId = "me.weishu.kernelsu";
    metadataYml = ''
      Categories:
        - System
      License: GPL-3.0-or-later
      WebSite: https://kernelsu.org/
      SourceCode: https://github.com/tiann/KernelSU
      IssueTracker: https://github.com/tiann/KernelSU/issues
      Changelog: https://github.com/tiann/KernelSU/releases
      AutoName: KernelSU
      Summary: Kernel-based root manager
      Description: |-
        KernelSU is a kernel-based root solution for Android with a
        companion manager app for granting root access, managing modules,
        and configuring policies.

        This package is the upstream manager app built from source.
      RequiresRoot: true
    '';
  };
}
