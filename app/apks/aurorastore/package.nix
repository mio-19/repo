{
  mk-apk-package,
  lib,
  jdk21_headless,
  gradle_9_3_1,
  stdenv,
  fetchgit,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  version = "4.8.2";

  src = fetchgit {
    url = "https://gitlab.com/AuroraOSS/AuroraStore.git";
    tag = version;
    hash = "sha256-HivKLMPJcMkiAPNw1RKMpr6g4B8Aq/jD4j5fXjFqr0c=";
  };

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-35-0-0
    s.build-tools-36-1-0
  ]);

  gradle = gradle_9_3_1;

  appPackage = stdenv.mkDerivation (finalAttrs: {
    pname = "aurorastore";
    inherit version src;

    dontUseGradleConfigure = true;

    gradleBuildTask = ":app:assembleVanillaRelease";
    gradleUpdateTask = finalAttrs.gradleBuildTask;

    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./aurorastore_deps.json;
      silent = false;
      useBwrap = false;
    };

    nativeBuildInputs = [
      androidSdk
      gradle
      jdk21_headless
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = jdk21_headless;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
    };

    preConfigure = ''
      export HOME="$TMPDIR/home"
      export ANDROID_USER_HOME="$HOME/.android"
      export GRADLE_USER_HOME="$HOME/.gradle"
      export KOTLIN_DAEMON_DIR="$HOME/.kotlin/daemon"
      export TERM=dumb
      mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME" "$KOTLIN_DAEMON_DIR"
      echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
    '';

    postPatch = ''
            substituteInPlace app/build.gradle.kts \
              --replace-fail '    compileSdk = 37' '    compileSdk = 36'

            pluginResolutionBlock=$'pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {\n                val agpVersion = requested.version ?: "8.13.2"\n                useModule("com.android.tools.build:gradle:$agpVersion")\n            }\n        }\n    }\n'
            if [[ -z "''${IN_GRADLE_UPDATE_DEPS:-}" ]]; then
              cacheRoot="${finalAttrs.mitmCache}"
              pluginResolutionBlock='pluginManagement {
          repositories {
              maven { url = uri("'"$cacheRoot"'/https/plugins.gradle.org/m2") }
              maven { url = uri("'"$cacheRoot"'/https/dl.google.com/dl/android/maven2") }
              maven { url = uri("'"$cacheRoot"'/https/repo.maven.apache.org/maven2") }
              maven { url = uri("'"$cacheRoot"'/https/jitpack.io") }
              maven { url = uri("'"$cacheRoot"'/https/developer.huawei.com/repo") }
          }
          resolutionStrategy {
              eachPlugin {
                  if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {
                      val agpVersion = requested.version ?: "8.13.2"
                      useModule("com.android.tools.build:gradle:$agpVersion")
                  }
              }
          }
      }'

              dependencyRepositoriesBlock='dependencyResolutionManagement {
          repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
          repositories {
              maven { url = uri("'"$cacheRoot"'/https/dl.google.com/dl/android/maven2") }
              maven { url = uri("'"$cacheRoot"'/https/repo.maven.apache.org/maven2") }
              maven { url = uri("'"$cacheRoot"'/https/jitpack.io") }
              maven { url = uri("'"$cacheRoot"'/https/developer.huawei.com/repo") }
          }
      }
      '

              substituteInPlace settings.gradle.kts \
                --replace-fail $'pluginManagement {\n    repositories {\n        gradlePluginPortal()\n        google()\n        mavenCentral()\n    }\n}' "$pluginResolutionBlock" \
                --replace-fail $'dependencyResolutionManagement {\n    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)\n    repositories {\n        google()\n        mavenCentral()\n        // libsu is only available via jitpack\n        maven("https://jitpack.io/") {\n            content {\n                includeModule("com.github.topjohnwu.libsu", "core")\n            }\n        }\n        // Only included in huawei variants\n        maven("https://developer.huawei.com/repo/") {\n            content {\n                includeGroup("com.huawei.hms")\n                includeGroup("com.huawei.android.hms")\n            }\n        }\n    }\n}' "$dependencyRepositoriesBlock"
            else
              substituteInPlace settings.gradle.kts \
                --replace-fail "pluginManagement {" "$pluginResolutionBlock"
            fi

            substituteInPlace app/build.gradle.kts \
              --replace-fail \
                'val lastCommitHash = providers.exec {' \
                'val lastCommitHash = providers.provider { "unknown" } /* patched for nix builds: no .git metadata */ ; if (false) { providers.exec {' \
              --replace-fail \
                '}.standardOutput.asText.map { it.trim() }' \
                '}.standardOutput.asText.map { it.trim() } }'

            if [[ -n "''${MITM_CACHE_HOST:-}" && -n "''${MITM_CACHE_PORT:-}" && -n "''${MITM_CACHE_CA:-}" ]]; then
              truststore="$PWD/mitm-truststore.jks"
              keytool -importcert -noprompt \
                -alias mitm-cache-ca \
                -file "$MITM_CACHE_CA" \
                -keystore "$truststore" \
                -storepass changeit

              cat >> gradle.properties <<EOF
            systemProp.http.proxyHost=$MITM_CACHE_HOST
            systemProp.http.proxyPort=$MITM_CACHE_PORT
            systemProp.https.proxyHost=$MITM_CACHE_HOST
            systemProp.https.proxyPort=$MITM_CACHE_PORT
            systemProp.javax.net.ssl.trustStore=$truststore
            systemProp.javax.net.ssl.trustStorePassword=changeit
      EOF
            fi
    '';

    gradleFlags = [
      "--no-daemon"
      "-Dorg.gradle.java.home=${jdk21_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      "-Dorg.gradle.jvmargs=-Xmx4096m"
    ];

    installPhase = ''
      runHook preInstall
      apk_dir="app/build/outputs/apk/vanilla/release"
      apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
      test -n "$apk_name"
      apk_path="$apk_dir/$apk_name"
      test -f "$apk_path"
      install -Dm644 "$apk_path" "$out/aurorastore.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "Aurora Store app built from source";
      homepage = "https://gitlab.com/AuroraOSS/AuroraStore";
      license = licenses.gpl3Plus;
      platforms = platforms.unix;
    };
  });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "aurorastore.apk";
  signScriptName = "sign-aurorastore";
  fdroid = {
    appId = "com.aurora.store";
    metadataYml = ''
      Categories:
        - App Store & Updater
      License: GPL-3.0-or-later
      SourceCode: https://gitlab.com/AuroraOSS/AuroraStore
      IssueTracker: https://gitlab.com/AuroraOSS/AuroraStore/-/issues
      Translation: https://hosted.weblate.org/projects/aurora-store/
      Changelog: https://gitlab.com/AuroraOSS/AuroraStore/-/releases
      AutoName: Aurora Store
      Summary: Alternative client for downloading apps from Google Play
      Description: |-
        Aurora Store is an alternative client for browsing and downloading apps
        from Google Play.
        This package is built from source.
    '';
  };
}
