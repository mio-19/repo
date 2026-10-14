{
  mk-apk-package,
  lib,
  jdk17_headless,
  gradle_7_5,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  runCommand,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-33
        s.build-tools-30-0-3
        s.build-tools-33-0-2
      ]);

      gradle = gradle_7_5;
      androidSdkRoot = "${androidSdk}/share/android-sdk";
      aapt2 = "${androidSdkRoot}/build-tools/33.0.2/aapt2";
      jdkHome = jdk17_headless.passthru.home;

      # JitPack no longer serves EasyWeather 1.3, so compile that library
      # from its git tag instead of resolving the published artifact.
      easyWeatherSrc = fetchFromGitHub {
        owner = "MagneFire";
        repo = "EasyWeather";
        tag = "1.3";
        hash = "sha256-VJBoTZ8Mq/QRA7z2vgg67hz65gXS71t3vfJd8D2Jax8=";
      };
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "asteroidos-sync";
      version = "0.29";

      src = fetchFromGitHub {
        owner = "AsteroidOS";
        repo = "AsteroidOSSync";
        tag = "v${finalAttrs.version}";
        hash = "sha256-ShYHGD52oEmWNlCgc1BUMyZPruVTMWoGkikG2bByZow=";
      };

      patches = [
        ./easyweather-from-source.patch
        ./asteroidos-find-phone.patch
      ];

      postPatch = ''
        cp -a ${easyWeatherSrc}/library/src/main/java/github app/src/main/java/
        chmod -R u+w app/src/main/java/github
        substituteInPlace app/src/main/java/github/vatsal/easyweather/retrofit/api/ApiClient.java \
          --replace-fail 'import android.support.annotation.NonNull;' 'import androidx.annotation.NonNull;'
      '';

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCacheOrig = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./asteroidos-sync_deps.json;
        silent = false;
        useBwrap = false;
      };

      # AGP 7.4's D8 crashes on the from-source builds of these jars. Put the
      # lockfile binaries back; every other overridden artifact stays as-is.
      gsonBinaryJar = fetchurl {
        url = "https://repo.maven.apache.org/maven2/com/google/code/gson/gson/2.10.1/gson-2.10.1.jar";
        hash = "sha256-QkHBSncnw0/uplB+yAExij1KkPBw5FJWgQefuU7kxZM=";
      };
      errorProneBinaryJar = fetchurl {
        url = "https://repo.maven.apache.org/maven2/com/google/errorprone/error_prone_annotations/2.15.0/error_prone_annotations-2.15.0.jar";
        hash = "sha256-BnBHcUNJ53iaW9v62dHAr586HrKMVaDuP2jmgvkFxOs=";
      };
      mitmCache = runCommand "${finalAttrs.pname}-deps" { } ''
        mkdir -p "$out"
        cp -a ${finalAttrs.mitmCacheOrig}/. "$out/"
        chmod -R u+w "$out"
        replace_jar() {
          rm -f "$1"
          cp "$2" "$1"
        }
        replace_jar \
          "$out/https/repo.maven.apache.org/maven2/com/google/code/gson/gson/2.10.1/gson-2.10.1.jar" \
          ${finalAttrs.gsonBinaryJar}
        replace_jar \
          "$out/https/repo.maven.apache.org/maven2/com/google/errorprone/error_prone_annotations/2.15.0/error_prone_annotations-2.15.0.jar" \
          ${finalAttrs.errorProneBinaryJar}
      '';

      nativeBuildInputs = [
        gradle
        jdk17_headless
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdkHome;
        ANDROID_HOME = androidSdkRoot;
        ANDROID_SDK_ROOT = androidSdkRoot;
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = aapt2;
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        # Keep a GRADLE_USER_HOME already set by the dependency update script.
        # Overriding it reuses a populated cache and drops those downloads
        # from the lockfile.
        if [ -z "''${GRADLE_USER_HOME:-}" ]; then
          export GRADLE_USER_HOME="$HOME/.gradle"
        fi
        mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"
        echo "sdk.dir=${androidSdkRoot}" > local.properties

        # Buildscript classpath downloads (AGP, Kotlin plugin) ignore http_proxy
        # unless Gradle is told to use the mitm-cache proxy explicitly.
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

        if [ ! -f "$ANDROID_USER_HOME/debug.keystore" ]; then
          keytool -genkeypair \
            -alias androiddebugkey \
            -keyalg RSA \
            -keysize 2048 \
            -validity 10000 \
            -storetype JKS \
            -keystore "$ANDROID_USER_HOME/debug.keystore" \
            -storepass android \
            -keypass android \
            -dname "CN=Android Debug,O=Android,C=US"
        fi
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "--no-daemon"
        "-Dorg.gradle.java.home=${jdkHome}"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdkHome}"
        "-Dandroid.aapt2FromMavenOverride=${aapt2}"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
      ];

      installPhase = ''
        runHook preInstall
        apk_path=""
        for candidate in \
          app/build/outputs/apk/release/app-release-unsigned.apk \
          app/build/outputs/apk/release/app-release.apk; do
          if [ -f "$candidate" ]; then
            apk_path="$candidate"
            break
          fi
        done
        test -n "$apk_path"
        install -Dm644 "$apk_path" "$out/asteroidos-sync.apk"
        runHook postInstall
      '';

      meta = with lib; {
        sourceProvenance = with sourceTypes; [ fromSource ];
        description = "Android companion for watches running AsteroidOS";
        homepage = "https://github.com/AsteroidOS/AsteroidOSSync";
        license = licenses.gpl3Plus;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "asteroidos-sync.apk";
  signScriptName = "sign-asteroidos-sync";
  fdroid = {
    appId = "org.asteroidos.sync";
    metadataYml = ''
      Categories:
        - Connectivity
      License: GPL-3.0-or-later
      SourceCode: https://github.com/AsteroidOS/AsteroidOSSync
      IssueTracker: https://github.com/AsteroidOS/AsteroidOSSync/issues
      Translation: https://hosted.weblate.org/projects/asteroidos/
      Changelog: https://github.com/AsteroidOS/AsteroidOSSync/releases
      AutoName: AsteroidOS Sync
      Summary: Synchronize a phone with an AsteroidOS watch
      Description: |-
        AsteroidOS Sync connects an Android phone to a watch running
        asteroid-btsyncd. It handles notifications, weather, and media
        controls for AsteroidOS.
        This package is built from source. EasyWeather is compiled from
        its git tag because the JitPack artifact is no longer published.
    '';
  };
}
