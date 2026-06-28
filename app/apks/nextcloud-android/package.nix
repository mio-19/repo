{
  mk-apk-package,
  overrides-fromsrc,
  gradle,
  lib,
  jdk25_headless,
  gradle_9_5_1,
  fetchFromGitHub,
  fetchurl,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-35-0-0
    s.build-tools-36-0-0
    s.ndk-29-0-14206865
    s.cmake-4-1-2
  ]);

  appPackage = gradle_9_5_1.stdenv.mkDerivation (finalAttrs: {
    pname = "nextcloud-android";
    version = "34.0.1";

    src = fetchFromGitHub {
      owner = "nextcloud";
      repo = "android";
      tag = "stable-${finalAttrs.version}";
      hash = "sha256-M+XbB35eNgMFGvoPaIxKMqfgen/BUwdtjwJDwdj/RiI=";
    };

    patches = [
      ./0001-use-explicit-maven-urls.patch
    ];

    gradleBuildTask = ":app:assembleGenericRelease";
    gradleUpdateTask = ":app:dependencies :appscan:dependencies :app:processGenericReleaseResources :app:compileGenericReleaseKotlin resolveAllDependencies --refresh-dependencies --no-build-cache --no-configuration-cache --no-daemon";

    passthru = {
      prefab_jar = fetchurl {
        url = "https://maven.google.com/com/google/prefab/cli/2.1.0/cli-2.1.0-all.jar";
        hash = "sha256-4hnIzWv9n/cVA6V8avNLm6Bg8DUlzD5YMw3uUyRaXtY=";
      };
      prefab_pom = fetchurl {
        url = "https://maven.google.com/com/google/prefab/cli/2.1.0/cli-2.1.0.pom";
        hash = "sha256-EQZho1OGgCq3MdEaDqBQRE/DyfMck28xo61Yv4Q74w8=";
      };
    };

    mitmCacheOrig = gradle_9_5_1.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./nextcloud-android_deps.json;
      silent = false;
      useBwrap = true;
    };

    mitmCache = finalAttrs.mitmCacheOrig.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        mkdir -p $out/https/maven.google.com/com/google/prefab/cli/2.1.0/
        cp ${finalAttrs.passthru.prefab_jar} $out/https/maven.google.com/com/google/prefab/cli/2.1.0/cli-2.1.0-all.jar
        cp ${finalAttrs.passthru.prefab_pom} $out/https/maven.google.com/com/google/prefab/cli/2.1.0/cli-2.1.0.pom
      '';
    });

    nativeBuildInputs = [
      androidSdk
      gradle_9_5_1
      jdk25_headless
      writableTmpDirAsHomeHook
      finalAttrs.mitmCache
    ];

    postPatch = ''
      rm -f gradle/verification-metadata.xml
    '';

    preConfigure = ''
      export PREFAB_JAR="${finalAttrs.passthru.prefab_jar}"
      export ANDROID_USER_HOME="$HOME/.android"
      export GRADLE_USER_HOME="$HOME/.gradle"
      export TERM=dumb
      mkdir -p "$ANDROID_USER_HOME"
      cat > local.properties <<EOF
      sdk.dir=${androidSdk}/share/android-sdk
      cmake.dir=${androidSdk}/share/android-sdk/cmake/4.1.2
      ndk.dir=${androidSdk}/share/android-sdk/ndk/29.0.14206865
      EOF

      cat > init-prefab.gradle <<EOF
      gradle.projectsEvaluated {
          rootProject.allprojects {
              configurations.all {
                  if (name == "_internal_prefab_binary") {
                      withDependencies { deps ->
                          deps.clear()
                          deps.add(project.dependencies.create(project.files(System.getenv("PREFAB_JAR"))))
                      }
                  }
              }
          }
      }

      rootProject {
          tasks.register("resolveAllDependencies") {
              doLast {
                  rootProject.allprojects.each { p ->
                      p.configurations.each { c ->
                          if (c.isCanBeResolved()) {
                              try {
                                  c.resolve()
                              } catch (Exception e) {
                                  // Ignore
                              }
                          }
                      }
                  }
              }
          }
      }
      EOF
      gradleFlagsArray+=(--init-script "init-prefab.gradle")
    '';

    gradleFlags = [
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk25_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    ];

    installPhase = ''
      runHook preInstall
      apk_dir="app/build/outputs/apk/generic/release"
      apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
      test -n "$apk_name"
      apk_path="$apk_dir/$apk_name"
      test -f "$apk_path"
      badging="$("${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt" dump badging "$apk_path")"
      pkg="$(echo "$badging" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")"
      [ "$pkg" = "com.nextcloud.client" ]
      install -Dm644 "$apk_path" "$out/nextcloud-android.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "Nextcloud Android app built from source";
      homepage = "https://github.com/nextcloud/android";
      license = licenses.agpl3Plus;
      platforms = platforms.unix;
    };
  });

in
mk-apk-package {
  inherit appPackage;
  mainApk = "nextcloud-android.apk";
  signScriptName = "sign-nextcloud-android";
  fdroid = {
    appId = "com.nextcloud.client";
    metadataYml = ''
      Categories:
        - Cloud Storage & File Sync
      License: AGPL-3.0-or-later
      WebSite: https://nextcloud.com/
      SourceCode: https://github.com/nextcloud/android
      IssueTracker: https://github.com/nextcloud/android/issues
      Changelog: https://github.com/nextcloud/android/releases
      AutoName: Nextcloud
      Summary: Access and sync your Nextcloud files
      Description: |-
        Nextcloud lets you browse, upload, and synchronize files with your
        Nextcloud server from Android.
        This package is built from source from the upstream nextcloud/android
        repository using the generic (F-Droid compatible) flavor.
    '';
  };
}
