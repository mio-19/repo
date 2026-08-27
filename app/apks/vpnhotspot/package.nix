{
  agp-resolution,
  mk-apk-package,
  lib,
  jdk21_headless,
  gradle_8_14_3,
  stdenv,
  fetchgit,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
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
        s.ndk-27-3-13750724
        s.cmake-3-31-6
      ]);

      gradle = gradle_8_14_3;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "vpnhotspot";
      version = "2.19.1";
      /*
        src = fetchgit {
          url = "https://codeberg.org/zinga/VPNHotspot.git";
          rev = "db3dcedc3c2b40929e3e0c04fed457cf5003457f";
          hash = "sha256-fCMve90QwT2K0axT1JHZ774ciko5+XSo4hZou+KfHQk=";
        };
      */
      src = fetchgit {
        url = "https://github.com/Mygod/VPNHotspot.git";
        tag = "v${finalAttrs.version}";
        hash = "sha256-706n9cGGZYxB3KG7/MWbsTfICfHJpaXygihBs+MeaGA=";
      };

      gradleBuildTask = ":mobile:assembleFreedomRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./vpnhotspot_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21_headless
        writableTmpDirAsHomeHook
        git
      ];

      env = {
        JAVA_HOME = jdk21_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
      };

      # foss.patch: https://github.com/Mygod/VPNHotspot.git vs https://codeberg.org/zinga/VPNHotspot.git v2.19.1
      postPatch =
        agp-resolution.patchSettingsGradle {
          agpVersion = "8.11.0";
          extraPlugins = [
            {
              ids = [ "org.jetbrains.kotlin.android" ];
              module = "org.jetbrains.kotlin:kotlin-gradle-plugin";
              version = "2.2.0";
            }
            {
              ids = [ "org.jetbrains.kotlin.plugin.compose" ];
              module = "org.jetbrains.kotlin:compose-compiler-gradle-plugin";
              version = "2.2.0";
            }
            {
              ids = [ "com.google.devtools.ksp" ];
              module = "com.google.devtools.ksp:symbol-processing-gradle-plugin";
              version = "2.2.0-2.0.2";
            }
            {
              ids = [ "com.github.ben-manes.versions" ];
              module = "com.github.ben-manes:gradle-versions-plugin";
              version = "0.52.0";
            }
          ];
        }
        + ''
          ${lib.getExe git} apply "${./foss.patch}"
          substituteInPlace mobile/build.gradle.kts \
                --replace-fail '    compileSdk = 36' '    compileSdk = 36
          ndkVersion = "27.3.13750724"'

          substituteInPlace mobile/build.gradle.kts \
                --replace-fail 'vcsInfo.include = true' 'vcsInfo.include = false'

          # Offline builds: point Gradle repos at mitmCache paths. Keep network
          # shortcuts during mitmCache.updateScript so new deps can be captured.
          if [[ -z "''${IN_GRADLE_UPDATE_DEPS:-}" && -d "${finalAttrs.mitmCache}" ]]; then
            substituteInPlace settings.gradle.kts \
              --replace-fail "google()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2\") }" \
              --replace-fail "mavenCentral()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }" \
              --replace-fail "gradlePluginPortal()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/plugins.gradle.org/m2\") }"
          fi
        '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        echo "ndk.dir=${androidSdk}/share/android-sdk/ndk/27.3.13750724" >> local.properties
        echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.31.6" >> local.properties
      '';

      gradleFlags = [
        "-xlintVitalFreedomRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 mobile/build/outputs/apk/freedom/release/mobile-freedom-release-unsigned.apk "$out/vpnhotspot.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Android VPN tethering and hotspot helper";
        homepage = "https://codeberg.org/zinga/VPNHotspot";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "vpnhotspot.apk";
  signScriptName = "sign-vpnhotspot";
  fdroid = {
    appId = "be.mygod.vpnhotspot_foss";
    metadataYml = ''
      Categories:
        - Connectivity
        - VPN & Proxy
      License: Apache-2.0
      AuthorName: zinga
      SourceCode: https://codeberg.org/zinga/VPNHotspot
      IssueTracker: https://codeberg.org/zinga/VPNHotspot/issues
      AutoName: VPN Hotspot
      Summary: Share VPN connections over hotspot and tethering
      Description: |-
        VPN Hotspot helps share a VPN connection over Wi-Fi hotspot,
        USB tethering, Bluetooth tethering, and related Android
        networking paths.

        This package is built from the same fork and freedom flavor
        used by F-Droid, while keeping this repo's newer NDK and CMake
        toolchain overrides for reproducible native builds.
      RequiresRoot: true
    '';
  };
}
