{
  mk-apk-package,
  lib,
  pkgs,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
  rustPlatform,
  cargo,
  rustc,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.platforms-android-36
        s.build-tools-35-0-0
        # AGP 9.0.1 / compileSdk 36 resolves aapt2 from build-tools 36.0.0.
        s.build-tools-36-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.3.1";
          hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
          defaultJava = jdk21;
        }).wrapped;

      # Pin derivation process (explicit):
      # 1) In bitwarden/android `gradle/libs.versions.toml`, app version `2026.3.0` points to
      #    `bitwardenSdk = "2.0.0-5676-14521973"`.
      # 2) We treated trailing `14521973` as the sdk-internal commit prefix and first pinned
      #    sdk-internal to `14521973668ec4f5e3de86e474637cc68bd70ac3`.
      # 3) With that pin, we hit app/sdk API drift around InitUserCryptoMethod and a runtime
      #    LocalUserDataKeyInitFailed path; after removing local shims, we pinned to
      #    `a6f4a23322c72d00b9ed7999441da66035ce7048`, which is the validated compatible rev.
      sdkSrc = fetchFromGitHub {
        owner = "bitwarden";
        repo = "sdk-internal";
        rev = "a6f4a23322c72d00b9ed7999441da66035ce7048";
        hash = "sha256-m+FCqTwTLJr+Z39uoTDFpgTsF4cod9h57X3PhVIi/ig=";
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
            androidNdkVersion = "29";
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
            androidNdkVersion = "29";
            useAndroidPrebuilt = true;
            rust.rustcTarget = "x86_64-linux-android";
          };
        }
      );

      mkBitwardenUniffi =
        {
          crossPkgs,
          rustTarget,
        }:
        crossPkgs.rustPlatform.buildRustPackage {
          pname = "bitwarden-uniffi";
          version = "2.0.0";

          src = sdkSrc;

          cargoLock = {
            lockFile = "${sdkSrc}/Cargo.lock";
            outputHashes = {
              "passkey-0.5.0" = "sha256-vOeb5y3NImP1YQxs70FRiJACtQK+IdtE0HeHHUJoK5o=";
              "uniffi-0.29.4" = "sha256-uUENtV5Oo+Gz5p44e+f2SDX6ea3tlWlLqAFOLBnxHwg=";
            };
          };

          doCheck = false;
          cargoBuildFlags = [ "-p bitwarden-uniffi" ];
          CARGO_BUILD_TARGET = rustTarget;
          preBuild = ''
            export RUST_LOG=info
          '';

          installPhase = ''
            runHook preInstall
            install -Dm755 \
              target/${rustTarget}/release/libbitwarden_uniffi.so \
              "$out/lib/libbitwarden_uniffi.so"
            runHook postInstall
          '';
        };

      uniffiArm64 = mkBitwardenUniffi {
        crossPkgs = aarch64AndroidPkgs;
        rustTarget = "aarch64-linux-android";
      };

      uniffiX8664 = mkBitwardenUniffi {
        crossPkgs = x86_64AndroidPkgs;
        rustTarget = "x86_64-linux-android";
      };

      uniffiBindgen = rustPlatform.buildRustPackage {
        pname = "bitwarden-uniffi-bindgen";
        version = "2.0.0";
        src = sdkSrc;
        cargoLock = {
          lockFile = "${sdkSrc}/Cargo.lock";
          outputHashes = {
            "passkey-0.5.0" = "sha256-vOeb5y3NImP1YQxs70FRiJACtQK+IdtE0HeHHUJoK5o=";
            "uniffi-0.29.4" = "sha256-uUENtV5Oo+Gz5p44e+f2SDX6ea3tlWlLqAFOLBnxHwg=";
          };
        };
        cargoBuildFlags = [ "-p uniffi-bindgen" ];
        doCheck = false;
        preBuild = ''
          export RUST_LOG=info
        '';
      };

      sdkGeneratedJava = stdenv.mkDerivation {
        pname = "bitwarden-sdk-generated-java";
        version = "2.0.0";
        src = sdkSrc;
        cargoRoot = ".";
        cargoDeps = rustPlatform.fetchCargoVendor {
          pname = "bitwarden-sdk-generated-java-vendor";
          version = "2.0.0";
          src = sdkSrc;
          cargoRoot = ".";
          hash = "sha256-tb6sJOvmJ5Jni4AZUXX9TT+N3/sw3XKfpe1ggMkJV0w=";
        };
        nativeBuildInputs = [
          rustPlatform.cargoSetupHook
          cargo
          rustc
          uniffiBindgen
        ];
        dontConfigure = true;
        dontFixup = true;
        buildPhase = ''
          runHook preBuild
          mkdir -p sdk/src/main/jniLibs/arm64-v8a
          cp ${uniffiArm64}/lib/libbitwarden_uniffi.so sdk/src/main/jniLibs/arm64-v8a/
          ${uniffiBindgen}/bin/uniffi-bindgen generate \
            ./sdk/src/main/jniLibs/arm64-v8a/libbitwarden_uniffi.so \
            --library \
            --language kotlin \
            --no-format \
            --out-dir sdk/src/main/java
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p "$out/java"
          cp -R sdk/src/main/java/. "$out/java/"
          runHook postInstall
        '';
      };

    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "bitwarden-android";
      version = "2026.3.0";

      src = fetchFromGitHub {
        owner = "bitwarden";
        repo = "android";
        tag = "v${finalAttrs.version}-bwpm";
        hash = "sha256-YjbMVFW6fWYuwRApISrEtRGZQOMGEUxvAGxzTDJcKBc=";
      };

      gradleBuildTask = ":app:assembleFdroidRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./bitwarden-android_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21
        apksigner
        writableTmpDirAsHomeHook
        git
      ];

      env = {
        JAVA_HOME = jdk21;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties

        # Use locally built sdk-internal artifact instead of private GitHub Packages.
        cat > user.properties <<EOF
        localSdk=true
        gitHubToken=
        EOF
        substituteInPlace gradle/libs.versions.toml \
          --replace-fail 'bitwarden-sdk = { module = "com.bitwarden:sdk-android", version.ref = "bitwardenSdk" }' 'bitwarden-sdk = { module = "com.bitwarden:sdk-android", version = "LOCAL" }'
      '';

      preBuild = ''
                repoRoot="$PWD"
                sdkKotlinDir="$PWD/.nix-sdk-internal/crates/bitwarden-uniffi/kotlin"
                mkdir -p "$PWD/.nix-sdk-internal"
                cp -R ${sdkSrc}/. "$PWD/.nix-sdk-internal/"
                chmod -R u+w "$PWD/.nix-sdk-internal"

                cd "$sdkKotlinDir"
                substituteInPlace build.gradle \
                  --replace-fail "id 'com.android.application' version '8.9.0' apply false" "id 'com.android.application' version '9.0.1' apply false" \
                  --replace-fail "id 'com.android.library' version '8.9.0' apply false" "id 'com.android.library' version '9.0.1' apply false" \
                  --replace-fail "id 'org.jetbrains.kotlin.android' version '2.1.0' apply false" "id 'org.jetbrains.kotlin.android' version '2.3.10' apply false" \
                  --replace-fail "id 'org.jetbrains.kotlin.plugin.serialization' version '2.1.0' apply false" "id 'org.jetbrains.kotlin.plugin.serialization' version '2.3.10' apply false" \
                  --replace-fail "id 'org.jetbrains.kotlin.plugin.compose' version '2.1.0' apply false" "id 'org.jetbrains.kotlin.plugin.compose' version '2.3.10' apply false"
                substituteInPlace app/build.gradle \
                  --replace-fail "id 'kotlinx-serialization'" "id 'org.jetbrains.kotlin.plugin.serialization'"
                substituteInPlace sdk/build.gradle \
                  --replace-fail "id 'org.jetbrains.kotlin.android'" "" \
                  --replace-fail "    kotlinOptions {
                jvmTarget = '1.8'
            }
        " "" \
                  --replace-fail "def branchName = 'git branch --show-current'.execute().text.trim()" "def branchName = 'main'" \
                  --replace-fail "implementation files(findRustlsPlatformVerifierClassesJar())" ""
                substituteInPlace settings.gradle \
                  --replace-fail "pluginManagement {" "pluginManagement {
                      resolutionStrategy {
                          eachPlugin {
                              if (requested.id.id == \"com.android.application\" || requested.id.id == \"com.android.library\") {
                                  useModule(\"com.android.tools.build:gradle:9.0.1\")
                              }
                              if (requested.id.id == \"org.jetbrains.kotlin.android\" || requested.id.id == \"org.jetbrains.kotlin.plugin.serialization\" || requested.id.id == \"org.jetbrains.kotlin.plugin.compose\") {
                                  useModule(\"org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.10\")
                              }
                          }
                      }"
                substituteInPlace settings.gradle \
                  --replace-fail "include ':app'" ""
                if [[ -z "''${IN_GRADLE_UPDATE_DEPS:-}" && -d "${finalAttrs.mitmCache}" ]]; then
                  substituteInPlace settings.gradle \
                    --replace-fail "google()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2\") }" \
                    --replace-fail "mavenCentral()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }" \
                    --replace-fail "gradlePluginPortal()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/plugins.gradle.org/m2\") }"
                fi
                if [[ -n "''${IN_GRADLE_UPDATE_DEPS:-}" ]]; then
                  bootstrapDir="$(mktemp -d)"
                  cat > "$bootstrapDir/build.gradle" <<'EOF'
        repositories {
            google()
            mavenCentral()
            gradlePluginPortal()
        }

        configurations {
            bootstrap
        }

        dependencies {
            bootstrap "org.jetbrains.kotlin:kotlin-stdlib:2.2.10"
            bootstrap "org.jetbrains.kotlin:kotlin-reflect:2.2.10"
            bootstrap "org.jetbrains:annotations:23.0.0"
            bootstrap "commons-codec:commons-codec:1.17.1"
            bootstrap "org.apache.commons:commons-lang3:3.16.0"
        }

        tasks.register("resolveBootstrap") {
            doLast {
                configurations.bootstrap.resolve()
            }
        }
        EOF
                  ${gradle}/bin/gradle --no-daemon -p "$bootstrapDir" resolveBootstrap
                fi

                mkdir -p ./sdk/src/main/jniLibs/{arm64-v8a,x86_64}
                cp ${uniffiArm64}/lib/libbitwarden_uniffi.so ./sdk/src/main/jniLibs/arm64-v8a/
                cp ${uniffiX8664}/lib/libbitwarden_uniffi.so ./sdk/src/main/jniLibs/x86_64/

                mkdir -p ./sdk/src/main/java
                cp -R ${sdkGeneratedJava}/java/. ./sdk/src/main/java/
                chmod -R u+w ./sdk/src/main/java
                ${gradle}/bin/gradle --no-daemon sdk:publishToMavenLocal -Pversion=LOCAL

                cd "$repoRoot"
      '';

      gradleFlags = [
        "-xlintVitalFdroidRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 \
          app/build/outputs/apk/fdroid/release/com.x8bit.bitwarden-fdroid.apk \
          "$out/bitwarden-android.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Bitwarden Android password manager (F-Droid flavor, unsigned)";
        homepage = "https://github.com/bitwarden/android";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "bitwarden-android.apk";
  signScriptName = "sign-bitwarden-android";
  fdroid = {
    appId = "com.x8bit.bitwarden";
    metadataYml = ''
      Categories:
        - Security
      License: GPL-3.0-only
      SourceCode: https://github.com/bitwarden/android
      IssueTracker: https://github.com/bitwarden/android/issues
      Changelog: https://github.com/bitwarden/android/releases
      AutoName: Bitwarden
      Summary: Password manager and secure vault
      Description: |-
        Bitwarden is an open-source password manager for securely storing,
        generating, and autofilling credentials.

        This package builds the upstream F-Droid flavor from source.
    '';
  };
}
