{
  mk-apk-package,
  lib,
  pkgs,
  gradle_9_3_1,
  jdk25_headless,
  stdenv,
  fetchFromGitHub,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
  rustPlatform,
  cargo,
  rustc,
  fetchurl,
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

      gradle = gradle_9_3_1;

      # https://github.com/bitwarden/android/blob/v2026.3.1-bwpm/gradle/libs.versions.toml#L33 bitwardenSdk = "2.0.0-5676-14521973"
      sdkSrc = fetchFromGitHub {
        owner = "bitwarden";
        repo = "sdk-internal";
        rev = "14521973668ec4f5e3de86e474637cc68bd70ac3";
        hash = "sha256-EZZa3Cv7HdQKy9JCqqrn6s/CQJ1LECvl5UIWSztvIKE=";
      };

      sdkSrcLock = fetchurl {
        url = "${sdkSrc.meta.homepage}/raw/${sdkSrc.rev}/Cargo.lock";
        hash = "sha256-dZGh3z/twScrWkX1rcJWmcnqorsVYQq3ZbKgCsooE8o=";
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
            # this cause whole src to be fetched during evaluation
            #lockFile = "${sdkSrc}/Cargo.lock";
            # this only fetches one file during nix evaluation
            lockFile = sdkSrcLock;
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
          # this cause whole src to be fetched during evaluation
          #lockFile = "${sdkSrc}/Cargo.lock";
          # this only fetches one file during nix evaluation
          lockFile = sdkSrcLock;
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
          hash = "sha256-ILDl8qR0luBep87KVh8xyEDsWNNda4CPm95+qB/u2TQ=";
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
      version = "2026.3.1";

      src = fetchFromGitHub {
        owner = "bitwarden";
        repo = "android";
        tag = "v${finalAttrs.version}-bwpm";
        hash = "sha256-8XXP3Ve3Uj+kwqRR8aWHnFOsC8wMAfs14CGA+E8Lny8=";
      };

      gradleBuildTask = ":app:assembleFdroidRelease";
      gradleUpdateTask = "resolveNixBootstrapDeps :app:assembleFdroidRelease";

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./bitwarden-android_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk25_headless
        writableTmpDirAsHomeHook
        git
      ];

      env = {
        JAVA_HOME = jdk25_headless;
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
        if [[ -n "''${IN_GRADLE_UPDATE_DEPS:-}" ]]; then
          export GRADLE_USER_HOME="$(mktemp -d)"
        fi
        substituteInPlace gradle/libs.versions.toml \
          --replace-fail 'bitwarden-sdk = { module = "com.bitwarden:sdk-android", version.ref = "bitwardenSdk" }' 'bitwarden-sdk = { module = "com.bitwarden:sdk-android", version = "LOCAL" }'
        cat >> build.gradle.kts <<'EOF'
        val nixBootstrap by configurations.creating
        dependencies {
            nixBootstrap("org.jetbrains.kotlin:kotlin-stdlib:2.2.10")
            nixBootstrap("org.jetbrains.kotlin:kotlin-stdlib:2.3.20")
            nixBootstrap("org.jetbrains.kotlin:kotlin-reflect:2.2.10")
            nixBootstrap("org.jetbrains:annotations:23.0.0")
            nixBootstrap("commons-codec:commons-codec:1.17.1")
            nixBootstrap("org.apache.commons:commons-lang3:3.16.0")
            nixBootstrap("org.apache.commons:commons-compress:1.27.1")
            nixBootstrap("commons-io:commons-io:2.16.1")
            nixBootstrap("com.google.code.gson:gson:2.11.0")
            nixBootstrap("org.bouncycastle:bcprov-jdk18on:1.79")
            nixBootstrap("com.google.errorprone:error_prone_annotations:2.28.0")
            nixBootstrap("net.java.dev.jna:jna:5.17.0")
            nixBootstrap("androidx.core:core-ktx:1.15.0")
            nixBootstrap("androidx.core:core:1.15.0")
            nixBootstrap("androidx.core:core-ktx:1.18.0")
            nixBootstrap("androidx.collection:collection:1.0.0")
            nixBootstrap("androidx.collection:collection:1.0.0@jar")
            nixBootstrap("androidx.versionedparcelable:versionedparcelable:1.1.1")
            nixBootstrap("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
            nixBootstrap("org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.10.2")
            nixBootstrap("org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.8.0")
            nixBootstrap("org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.8.0@jar")
            nixBootstrap("org.jetbrains.kotlin:kotlin-build-tools-compat:2.3.20")
            nixBootstrap("org.jetbrains.kotlin:kotlin-build-tools-impl:2.3.20")
            nixBootstrap("org.jetbrains.kotlin:kotlin-reflect:1.6.10")
        }
        tasks.register("resolveNixBootstrapDeps") {
            doLast {
                nixBootstrap.resolve()
                configurations.detachedConfiguration(
                    dependencies.create("org.jetbrains.kotlin:kotlin-stdlib:2.2.10"),
                    dependencies.create("org.jetbrains.kotlin:kotlin-reflect:2.2.10"),
                    dependencies.create("org.jetbrains.kotlin:kotlin-stdlib:1.6.10"),
                    dependencies.create("org.jetbrains.kotlin:kotlin-reflect:1.6.10"),
                    dependencies.create("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2"),
                    dependencies.create("org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.10.2"),
                    dependencies.create("org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.8.0@jar")
                ).resolve()
                val nixJvmBootstrap = configurations.detachedConfiguration(
                    dependencies.create("org.jetbrains.kotlin:kotlin-reflect:1.6.10"),
                    dependencies.create("org.jetbrains.kotlin:kotlin-stdlib:1.6.10"),
                    dependencies.create("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2"),
                    dependencies.create("org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.10.2"),
                    dependencies.create("org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.8.0@jar")
                ).apply {
                    isCanBeConsumed = false
                    isCanBeResolved = true
                    attributes {
                        attribute(org.gradle.api.attributes.Category.CATEGORY_ATTRIBUTE, objects.named(org.gradle.api.attributes.Category.LIBRARY))
                        attribute(org.gradle.api.attributes.Usage.USAGE_ATTRIBUTE, objects.named(org.gradle.api.attributes.Usage.JAVA_RUNTIME))
                        attribute(org.gradle.api.attributes.LibraryElements.LIBRARY_ELEMENTS_ATTRIBUTE, objects.named(org.gradle.api.attributes.LibraryElements.JAR))
                        attribute(org.gradle.api.attributes.Bundling.BUNDLING_ATTRIBUTE, objects.named(org.gradle.api.attributes.Bundling.EXTERNAL))
                    }
                }
                nixJvmBootstrap.resolve()
                val coroutinesCore18Jar = (dependencies.create("org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.8.0") as org.gradle.api.artifacts.ExternalModuleDependency).apply {
                    artifact {
                        type = "jar"
                        extension = "jar"
                    }
                }
                configurations.detachedConfiguration(coroutinesCore18Jar).apply {
                    isTransitive = false
                }.resolve()
                val coreKtx115 = (dependencies.create("androidx.core:core-ktx:1.15.0") as org.gradle.api.artifacts.ExternalModuleDependency).apply {
                    artifact {
                        type = "aar"
                        extension = "aar"
                    }
                }
                configurations.detachedConfiguration(coreKtx115).apply {
                    isTransitive = false
                }.resolve()
                val core115 = (dependencies.create("androidx.core:core:1.15.0") as org.gradle.api.artifacts.ExternalModuleDependency).apply {
                    artifact {
                        type = "aar"
                        extension = "aar"
                    }
                }
                configurations.detachedConfiguration(core115).apply {
                    isTransitive = false
                }.resolve()
                buildscript.configurations.getByName("classpath").resolve()
                allprojects.forEach {
                    it.buildscript.configurations.findByName("classpath")?.resolve()
                }
            }
        }
        EOF
      '';

      preBuild = ''
                repoRoot="$PWD"
                sdkKotlinDir="$PWD/.nix-sdk-internal/crates/bitwarden-uniffi/kotlin"
                mkdir -p "$PWD/.nix-sdk-internal"
                cp -R ${sdkSrc}/. "$PWD/.nix-sdk-internal/"
                chmod -R u+w "$PWD/.nix-sdk-internal"

                cd "$sdkKotlinDir"
                substituteInPlace build.gradle \
                  --replace-fail "id 'com.android.application' version '8.9.0' apply false" "id 'com.android.application' version '9.1.0' apply false" \
                  --replace-fail "id 'com.android.library' version '8.9.0' apply false" "id 'com.android.library' version '9.1.0' apply false" \
                  --replace-fail "id 'org.jetbrains.kotlin.android' version '2.1.0' apply false" "id 'org.jetbrains.kotlin.android' version '2.3.20' apply false" \
                  --replace-fail "id 'org.jetbrains.kotlin.plugin.serialization' version '2.1.0' apply false" "id 'org.jetbrains.kotlin.plugin.serialization' version '2.3.20' apply false" \
                  --replace-fail "id 'org.jetbrains.kotlin.plugin.compose' version '2.1.0' apply false" "id 'org.jetbrains.kotlin.plugin.compose' version '2.3.20' apply false"
                substituteInPlace app/build.gradle \
                  --replace-fail "id 'kotlinx-serialization'" "id 'org.jetbrains.kotlin.plugin.serialization'"
                substituteInPlace sdk/build.gradle \
                  --replace-fail "id 'org.jetbrains.kotlin.android'" "" \
                  --replace-fail "    kotlinOptions {
                jvmTarget = '1.8'
            }
        " "" \
                  --replace-fail "def branchName = 'git branch --show-current'.execute().text.trim()" "def branchName = 'main'" \
                  --replace-fail "implementation 'androidx.core:core-ktx:1.15.0'" "implementation('androidx.core:core-ktx:1.15.0') { exclude group: 'androidx.collection', module: 'collection' }" \
                  --replace-fail "implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.1'" "implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2'; implementation 'androidx.collection:collection:1.4.2'" \
                  --replace-fail "dependencies {" "tasks.matching { it.name == 'extractReleaseAnnotations' }.configureEach { enabled = false }; dependencies {" \
                  --replace-fail "implementation files(findRustlsPlatformVerifierClassesJar())" ""
                substituteInPlace settings.gradle \
                  --replace-fail "pluginManagement {" "pluginManagement {
                      resolutionStrategy {
                          eachPlugin {
                              if (requested.id.id == \"com.android.application\" || requested.id.id == \"com.android.library\") {
                                  useModule(\"com.android.tools.build:gradle:9.1.0\")
                              }
                              if (requested.id.id == \"org.jetbrains.kotlin.android\" || requested.id.id == \"org.jetbrains.kotlin.plugin.serialization\" || requested.id.id == \"org.jetbrains.kotlin.plugin.compose\") {
                                  useModule(\"org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.20\")
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
                mkdir -p ./sdk/src/main/jniLibs/{arm64-v8a,x86_64}
                cp ${uniffiArm64}/lib/libbitwarden_uniffi.so ./sdk/src/main/jniLibs/arm64-v8a/
                cp ${uniffiX8664}/lib/libbitwarden_uniffi.so ./sdk/src/main/jniLibs/x86_64/

                mkdir -p ./sdk/src/main/java
                cp -R ${sdkGeneratedJava}/java/. ./sdk/src/main/java/
                chmod -R u+w ./sdk/src/main/java
                mkdir -p ./sdk/build/intermediates/annotations_typedef_file/release/extractReleaseAnnotations
                : > ./sdk/build/intermediates/annotations_typedef_file/release/extractReleaseAnnotations/typedefs.txt
                if [[ -z "''${IN_GRADLE_UPDATE_DEPS:-}" ]]; then
                  ${gradle}/bin/gradle --no-daemon sdk:publishToMavenLocal -Pversion=LOCAL
                fi

                cd "$repoRoot"
      '';

      gradleFlags = [
        "-xlintVitalFdroidRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk25_headless}"
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
