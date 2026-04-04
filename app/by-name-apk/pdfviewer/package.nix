{
  mk-apk-package,
  sources,
  lib,
  jdk21,
  jdk17,
  gradle-packages,
  stdenv,
  fetchpatch,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  nodejs,
}:
let

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-36-1-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.4.0";
          hash = "sha256-YOpyM1bYEmPoAC/sD8+eKw7uDAhQx6PXqwpj8szGAfM=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "pdfviewer";
      inherit (sources.grapheneos_pdfviewer)
        src
        version
        ;

      patches = [
        (fetchpatch {
          name = "Add page persistence";
          url = "https://github.com/GrapheneOS/PdfViewer/pull/598.diff";
          hash = "sha256-xE8bc5u2IoRhfay8eJo+vUzzQEr4jGTWNEuciNT5W1U=";
        })
        (fetchpatch {
          name = "feat: Search (Fixes #4)";
          url = "https://github.com/GrapheneOS/PdfViewer/pull/579.diff";
          hash = "sha256-COVebkjyEIrQf7Q1VBLaRwthO2bG+/Uy/tBqoLueqwY=";
        })
      ];

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./pdfviewer_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21
        jdk17
        apksigner
        writableTmpDirAsHomeHook
        nodejs
      ];

      env = {
        JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
      };

      preConfigure = ''
        for proxy_var in http_proxy https_proxy HTTP_PROXY HTTPS_PROXY; do
          proxy_val="$(printenv "$proxy_var" || true)"
          if [ -n "$proxy_val" ] && [ "''${proxy_val#*://}" = "$proxy_val" ]; then
            export "$proxy_var=http://$proxy_val"
          fi
        done
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      postPatch = ''
        rm app/src/main/res/values/strings.xml.orig
        substituteInPlace app/build.gradle.kts \
              --replace-fail \
              'commandLine(getCommand("npm"), "ci", "--ignore-scripts")' \
              'environment("npm_config_audit", "false")
        environment("NPM_CONFIG_AUDIT", "false")
        environment("npm_config_update_notifier", "false")
        environment("NPM_CONFIG_UPDATE_NOTIFIER", "false")
        environment("npm_config_production", "false")
        environment("NPM_CONFIG_PRODUCTION", "false")
        environment("npm_config_omit", "")
        environment("NPM_CONFIG_OMIT", "")
        val normalizeProxy: (String) -> String? = { key ->
            System.getenv(key)?.let { if (it.contains("://")) it else "http://$it" }
        }
        normalizeProxy("http_proxy")?.let { environment("http_proxy", it) }
        normalizeProxy("https_proxy")?.let { environment("https_proxy", it) }
        normalizeProxy("HTTP_PROXY")?.let { environment("HTTP_PROXY", it) }
        normalizeProxy("HTTPS_PROXY")?.let { environment("HTTPS_PROXY", it) }
        commandLine(getCommand("npm"), "ci", "--ignore-scripts", "--no-audit", "--include=dev", "--cache", ".npm-cache")'

        substituteInPlace process_static.js \
              --replace-fail \
              'await commandLine(getCommand("node_modules/.bin/eslint"), ".");' \
              'void 0;'
      '';

      gradleFlags =
        let
          postfix = if stdenv.isDarwin then "" else "/lib/openjdk";
        in
        [
          "-xlintVitalRelease"
          "-Dorg.gradle.java.installations.auto-download=false"
          "-Dorg.gradle.java.installations.paths=${jdk17}${postfix},${jdk21}${postfix}"
          "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
          "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
        ];

      installPhase = ''
        runHook preInstall
        apk_path="$(echo app/build/outputs/apk/release/*-release-unsigned.apk)"
        install -Dm644 "$apk_path" "$out/pdfviewer.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "GrapheneOS PDF Viewer app (unsigned APK)";
        homepage = "https://github.com/GrapheneOS/PdfViewer";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "pdfviewer.apk";
  signScriptName = "sign-pdfviewer";
  fdroid = {
    appId = "app.grapheneos.pdfviewer";
    metadataYml = ''
      Categories:
        - Reading
      Changelog: https://github.com/GrapheneOS/PdfViewer/releases
      License: Apache-2.0
      SourceCode: https://github.com/GrapheneOS/PdfViewer
      IssueTracker: https://github.com/GrapheneOS/PdfViewer/issues
      AutoName: PDF Viewer
      Summary: Minimal secure PDF viewer
      Description: |-
        GrapheneOS PDF Viewer is a minimal and secure PDF viewer.
        This package is built from source.
    '';
  };
}
