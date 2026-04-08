{
  mk-apk-package,
  overrides-from-source,
  gradle2nixBuilders,
  sources,
  lib,
  jdk21,
  jdk17,
  gradle-packages,
  fetchpatch,
  fetchNpmDeps,
  npmHooks,
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
    gradle2nixBuilders.buildGradlePackage rec {
      pname = "pdfviewer";
      inherit (sources.grapheneos_pdfviewer)
        src
        version
        ;

      inherit gradle;

      lockFile = ./gradle.lock;
      overrides = overrides-from-source;
      buildJdk = jdk21;

      npmDeps = fetchNpmDeps {
        pname = "npm-deps-${pname}";
        inherit version src;
        hash = "sha256-XbFZycYjXiX9AV4cwwvcMuQk82wlExh8bVkVQFOZ/es=";
      };

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

      nativeBuildInputs = [
        androidSdk
        gradle
        jdk21
        jdk17
        apksigner
        writableTmpDirAsHomeHook
        npmHooks.npmConfigHook
        nodejs
      ];

      dontUseGradleConfigure = true;

      env = {
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
        export GRADLE_USER_HOME="$(mktemp -d)"
        export TERM=dumb
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        gradleFlagsArray+=(--no-daemon --init-script "$gradleInitScript" --offline)
      '';

      postPatch = ''
        rm -f gradle/verification-metadata.xml

        pluginResolutionBlock=$'pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {\n                val agpVersion = requested.version ?: "9.0.0"\n                useModule("com.android.tools.build:gradle:$agpVersion")\n            }\n        }\n    }\n'
        substituteInPlace settings.gradle.kts \
          --replace-fail "pluginManagement {" "$pluginResolutionBlock"

        rm app/src/main/res/values/strings.xml.orig
        substituteInPlace app/build.gradle.kts \
              --replace-fail \
              'commandLine(getCommand("npm"), "ci", "--ignore-scripts")' \
              'commandLine("true")'

        substituteInPlace process_static.js \
              --replace-fail \
              'await commandLine(getCommand("node_modules/.bin/eslint"), ".");' \
              'void 0;'
      '';

      gradleFlags = [
        "-Dorg.gradle.java.home=${jdk21.home}"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17}/lib/openjdk,${jdk21}/lib/openjdk"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      ];

      gradleBuildFlags = ":app:assembleRelease";

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
    };
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
