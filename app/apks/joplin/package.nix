{
  mk-apk-package,
  lib,
  jdk21_headless,
  jdk17_headless,
  gradle_8_14_3,
  stdenv,
  ninja,
  git,
  fetchFromGitHub,
  yarn-berry_4,
  nodejs,
  error_prone_annotations_2_28_0,

  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      gradle = gradle_8_14_3;

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-31
        s.platforms-android-35
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-0-0
        s.cmake-3-31-6
        s.ndk-27-0-12077973
        s.ndk-27-1-12297006
      ]);

      androidSdkRoot = "${androidSdk}/share/android-sdk";
      aapt2Path = "${androidSdkRoot}/build-tools/36.0.0/aapt2";
      jdk17Home = jdk17_headless.passthru.home;
      jdk21Home = jdk21_headless.passthru.home;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "joplin";
      version = "3.7.6";

      src = fetchFromGitHub {
        owner = "laurent22";
        repo = "joplin";
        tag = "android-v${finalAttrs.version}";
        hash = "sha256-rlqXRUGzmgKeb0nxC3SizvC7wlUclD/ArF01z2o/UvM=";
      };

      sourceRoot = "${finalAttrs.src.name}";

      patches = [
        ./use-debug-signing.patch
        ./rollup-config-extension.patch
      ];

      missingHashes = ./missing-hashes.json;

      offlineCache = yarn-berry_4.fetchYarnBerryDeps {
        inherit (finalAttrs)
          src
          patches
          missingHashes
          ;
        hash = "sha256-rYq+36+BWRD4Pq8DUkmYdhhcuILZ5rFUYj9aW9smS0E=";
      };

      gradleBuildTask = ":app:assembleRelease -x :app:lintVitalAnalyzeRelease -x :app:lintVitalReportRelease -x :app:lintVitalRelease";
      gradleUpdateTask = ''
        :app:assembleRelease
        :app:lintVitalAnalyzeRelease
        :expo-gradle-plugin:expo-autolinking-plugin-shared:compileKotlin
        :gradle-plugin:shared:compileKotlin
        :gradle-plugin:settings-plugin:compileKotlin
      '';

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./joplin_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21_headless
        jdk17_headless
        git
        nodejs
        yarn-berry_4.yarnBerryConfigHook
        ninja

        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk17Home;
        ANDROID_HOME = androidSdkRoot;
        ANDROID_SDK_ROOT = androidSdkRoot;
        ANDROID_NDK_ROOT = "${androidSdkRoot}/ndk/27.0.12077973";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = aapt2Path;
        GRADLE_OPTS = "-Dorg.gradle.java.installations.auto-download=false -Dorg.gradle.java.installations.paths=${jdk17Home},${jdk21Home}";
        NODE_ENV = "development";
        YARN_ENABLE_SCRIPTS = "0";
        ERROR_PRONE_ANNOTATIONS = "${error_prone_annotations_2_28_0}";
      };

      postConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        cat > packages/app-mobile/android/local.properties <<EOF
        sdk.dir=${androidSdkRoot}
        cmake.dir=${androidSdkRoot}/cmake/3.31.6
        EOF
      '';

      preBuild = ''
        # Foojay toolchain resolver tries to download JDKs; we pin installations via GRADLE_OPTS.
        # Removed substituteInPlace because foojay plugin was removed in upstream RN plugin 0.81.6

        source ${./rewrite-mitm-repos.sh}
        pin_expo_kotlin_jvm_plugin
        for f in \
          packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/expo-autolinking-plugin-shared/build.gradle.kts \
          packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/expo-autolinking-plugin/build.gradle.kts \
          packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/expo-autolinking-settings-plugin/build.gradle.kts \
          packages/app-mobile/node_modules/@react-native/gradle-plugin/shared/build.gradle.kts \
          packages/app-mobile/node_modules/@react-native/gradle-plugin/settings-plugin/build.gradle.kts; do
          ensure_gradle_plugin_portal "$f"
        done

        if [[ -z "''${IN_GRADLE_UPDATE_DEPS:-}" && -d "${finalAttrs.mitmCache}" ]]; then
          export JOPLIN_MITM_CACHE="${finalAttrs.mitmCache}"
          export JOPLIN_MITM_OVERLAY="$PWD/.gradle-mitm-overlay"
          rewrite_joplin_mitm_repos
        fi

        ${nodejs}/bin/node -e "const fs=require('fs'); const path=require('path'); let d=process.cwd(); while (d !== path.dirname(d) && !fs.existsSync(path.join(d,'packages','app-mobile','package.json'))) d = path.dirname(d); const f=require(path.join(d,'packages','tools','compilePackageInfo.js')); Promise.resolve(f(path.join(d,'packages','app-mobile','package.json'), path.join(d,'packages','app-mobile','packageInfo.js'))).catch(e=>{console.error(e); process.exit(1);});"
        patchShebangs packages/turndown/node_modules/rollup/dist/bin
        patchShebangs packages/turndown-plugin-gfm/node_modules/.bin
        export PATH="$PWD/packages/turndown/node_modules/.bin:$PWD/packages/turndown-plugin-gfm/node_modules/.bin:$PATH"
        (cd packages/turndown && npm run build-cjs)
        (cd packages/turndown-plugin-gfm && ${nodejs}/bin/node ../turndown/node_modules/rollup/dist/bin/rollup -c config/rollup.config.cjs.js && ${nodejs}/bin/node ../turndown/node_modules/rollup/dist/bin/rollup -c config/rollup.config.browser.cjs.js)
        ${lib.getExe yarn-berry_4} workspace @joplin/whisper-voice-typing build
        ${lib.getExe yarn-berry_4} workspace @joplin/fork-htmlparser2 build
        ${lib.getExe yarn-berry_4} tsc
        ${lib.getExe yarn-berry_4} workspace @joplin/app-mobile buildInjectedJs
        ${lib.getExe yarn-berry_4} workspace @joplin/app-mobile gulp encodeAssets

        if [[ -n "''${IN_GRADLE_UPDATE_DEPS:-}" ]]; then
          bootstrapDir="$(mktemp -d)"
          cat > "$bootstrapDir/build.gradle" <<'EOF'
        repositories {
            google()
            mavenCentral()
        }

        configurations {
            bootstrap {
                attributes {
                    attribute(Usage.USAGE_ATTRIBUTE, objects.named(Usage, Usage.JAVA_RUNTIME))
                    attribute(Category.CATEGORY_ATTRIBUTE, objects.named(Category, Category.LIBRARY))
                    attribute(LibraryElements.LIBRARY_ELEMENTS_ATTRIBUTE, objects.named(LibraryElements, LibraryElements.JAR))
                    attribute(TargetJvmEnvironment.TARGET_JVM_ENVIRONMENT_ATTRIBUTE, objects.named(TargetJvmEnvironment, TargetJvmEnvironment.STANDARD_JVM))
                }
            }
        }

        dependencies {
            bootstrap "org.jetbrains.kotlin:kotlin-stdlib:1.9.24"
            bootstrap "org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3"
            bootstrap "com.google.code.gson:gson:2.8.9"
            bootstrap "com.google.guava:guava:31.0.1-jre"
            bootstrap "com.squareup:javapoet:1.13.0"
            bootstrap "com.google.code.findbugs:jsr305:3.0.2"
            bootstrap "com.google.guava:failureaccess:1.0.1"
            bootstrap "com.google.guava:listenablefuture:9999.0-empty-to-avoid-conflict-with-guava"
            bootstrap "com.google.j2objc:j2objc-annotations:2.8"
            bootstrap("com.google.errorprone:error_prone_annotations") {
                version {
                    strictly "2.28.0"
                }
            }
            bootstrap "com.android.tools.lint:lint-gradle:31.11.0"
            bootstrap "org.apache.httpcomponents:httpclient:4.5.6"
            bootstrap "org.sonatype.oss:oss-parent:7@pom"
            bootstrap "org.sonatype.oss:oss-parent:9@pom"
        }

        tasks.register("resolveBootstrap") {
            doLast {
                configurations.bootstrap.resolve()
            }
        }
        EOF
          ${gradle}/bin/gradle --no-daemon -p "$bootstrapDir" resolveBootstrap
        fi
      '';

      preGradleUpdate = finalAttrs.preBuild;

      dontNpmBuild = true;
      dontYarnBuild = true;

      gradleFlags = [
        "--project-dir"
        "packages/app-mobile/android"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17Home},${jdk21Home}"
        "-Dandroid.aapt2FromMavenOverride=${aapt2Path}"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2Path}"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 \
          packages/app-mobile/android/app/build/outputs/apk/release/app-release.apk \
          "$out/joplin.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Joplin note-taking app for Android built from source";
        homepage = "https://github.com/laurent22/joplin";
        license = licenses.agpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "joplin.apk";
  signScriptName = "sign-joplin";
  fdroid = {
    appId = "net.cozic.joplin";
    metadataYml = ''
      Categories:
        - Writing
        - Office
      License: AGPL-3.0-only
      SourceCode: https://github.com/laurent22/joplin
      IssueTracker: https://github.com/laurent22/joplin/issues
      Changelog: https://github.com/laurent22/joplin/releases
      AutoName: Joplin
      Summary: Privacy-focused notes and to-dos with sync
      Description: |-
        Joplin is an open-source note-taking and to-do application.

        This package builds the upstream Android app from source.
    '';
  };
}
