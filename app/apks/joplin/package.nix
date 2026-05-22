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
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "joplin";
      version = "3.6.14";

      src = fetchFromGitHub {
        owner = "laurent22";
        repo = "joplin";
        tag = "v${finalAttrs.version}";
        hash = "sha256-C+253px2giINWjXsY2Jg/4M4hoFH7hWdIs4sAc6HUFw=";
      };

      sourceRoot = "${finalAttrs.src.name}";

      patches = [
        # Remove after upstream updates to Yarn 4.14.
        # https://github.com/laurent22/joplin/blob/dev/package.json#L103
        ./yarn-4.14-support.patch
      ];

      missingHashes = ./missing-hashes.json;

      offlineCache = yarn-berry_4.fetchYarnBerryDeps {
        inherit (finalAttrs)
          src
          patches
          missingHashes
          ;
        hash = "sha256-ejg0u9Dy3iaBusH248IbtJNpvd/zADyPJ9CplIK1A/w=";
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
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.0.12077973";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
        GRADLE_OPTS = "-Dorg.gradle.java.installations.auto-download=false -Dorg.gradle.java.installations.paths=${jdk17_headless},${jdk21_headless}";
        NODE_ENV = "development";
        YARN_ENABLE_SCRIPTS = "0";
      };

      postConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        cat > packages/app-mobile/android/local.properties <<EOF
        sdk.dir=${androidSdk}/share/android-sdk
        cmake.dir=${androidSdk}/share/android-sdk/cmake/3.31.6
        EOF
      '';

      preBuild = ''
                if grep -q "version '3.22.1'" packages/app-mobile/android/app/build.gradle; then
                  substituteInPlace packages/app-mobile/android/app/build.gradle \
                    --replace-fail "            version '3.22.1'" "            version '3.31.6'"
                fi
                if grep -q "signingConfig signingConfigs.release" packages/app-mobile/android/app/build.gradle; then
                  substituteInPlace packages/app-mobile/android/app/build.gradle \
                    --replace-fail "            signingConfig signingConfigs.release" "            signingConfig signingConfigs.debug"
                fi
                if grep -q 'id("org.gradle.toolchains.foojay-resolver-convention").version("0.5.0")' packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts; then
                  substituteInPlace packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts \
                    --replace-fail 'id("org.gradle.toolchains.foojay-resolver-convention").version("0.5.0")' ""
                fi
                if [[ -z "''${IN_GRADLE_UPDATE_DEPS:-}" && -d "${finalAttrs.mitmCache}" ]]; then
                  mitmOverlay="$PWD/.gradle-mitm-overlay"
                  for artifact in \
                    commons-codec/commons-codec/1.10 \
                    commons-logging/commons-logging/1.2 \
                    org/apache/httpcomponents/httpclient/4.5.6 \
                    org/apache/httpcomponents/httpcomponents-client/4.5.6 \
                    org/apache/httpcomponents/httpcore/4.4.10 \
                    org/apache/httpcomponents/httpcomponents-core/4.4.10 \
                    org/apache/httpcomponents/httpmime/4.5.6; do
                    mkdir -p "$mitmOverlay/$artifact"
                    ln -s "${finalAttrs.mitmCache}/https/plugins.gradle.org/m2/$artifact/"* \
                      "$mitmOverlay/$artifact/"
                  done
                  mkdir -p \
                    "$mitmOverlay/com/google/errorprone/error_prone_annotations/2.28.0" \
                    "$mitmOverlay/com/google/errorprone/error_prone_parent/2.28.0"
                  ln -s "${error_prone_annotations_2_28_0}/error_prone_annotations-2.28.0.jar" \
                    "$mitmOverlay/com/google/errorprone/error_prone_annotations/2.28.0/"
                  ln -s "${error_prone_annotations_2_28_0}/error_prone_annotations-2.28.0.pom" \
                    "$mitmOverlay/com/google/errorprone/error_prone_annotations/2.28.0/"
                  ln -s "${error_prone_annotations_2_28_0}/error_prone_parent-2.28.0.pom" \
                    "$mitmOverlay/com/google/errorprone/error_prone_parent/2.28.0/"
                  if grep -q "google()" packages/app-mobile/android/settings.gradle; then
                    substituteInPlace packages/app-mobile/android/settings.gradle \
                      --replace-fail "google()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2\") }"
                  fi
                  if grep -q "mavenCentral()" packages/app-mobile/android/settings.gradle; then
                    substituteInPlace packages/app-mobile/android/settings.gradle \
                      --replace-fail "mavenCentral()" "maven { url = uri(\"$mitmOverlay\") }
          maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
                  fi
                  if grep -q "gradlePluginPortal()" packages/app-mobile/android/settings.gradle; then
                    substituteInPlace packages/app-mobile/android/settings.gradle \
                      --replace-fail "gradlePluginPortal()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/plugins.gradle.org/m2\") }"
                  fi
                  if grep -q "google()" packages/app-mobile/android/build.gradle; then
                    substituteInPlace packages/app-mobile/android/build.gradle \
                      --replace-fail "google()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2\") }"
                  fi
                  if grep -q "mavenCentral()" packages/app-mobile/android/build.gradle; then
                    substituteInPlace packages/app-mobile/android/build.gradle \
                      --replace-fail "mavenCentral()" "maven { url = uri(\"$mitmOverlay\") }
          maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
                  fi
                  if grep -q "google()" packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts; then
                    substituteInPlace packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts \
                      --replace-fail "google()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2\") }"
                  fi
                  if grep -q "mavenCentral()" packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts; then
                    substituteInPlace packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts \
                      --replace-fail "mavenCentral()" "maven { url = uri(\"$mitmOverlay\") }
          maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
                  fi
                  if grep -q "gradlePluginPortal()" packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts; then
                    substituteInPlace packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts \
                      --replace-fail "gradlePluginPortal()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/plugins.gradle.org/m2\") }"
                  fi
                  if [ -f packages/app-mobile/node_modules/expo-modules-autolinking/android/settings.gradle.kts ]; then
                    if grep -q "google()" packages/app-mobile/node_modules/expo-modules-autolinking/android/settings.gradle.kts; then
                      substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/settings.gradle.kts \
                        --replace-fail "google()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2\") }"
                    fi
                    if grep -q "mavenCentral()" packages/app-mobile/node_modules/expo-modules-autolinking/android/settings.gradle.kts; then
                      substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/settings.gradle.kts \
                        --replace-fail "mavenCentral()" "maven { url = uri(\"$mitmOverlay\") }
          maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
                    fi
                    if grep -q "gradlePluginPortal()" packages/app-mobile/node_modules/expo-modules-autolinking/android/settings.gradle.kts; then
                      substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/settings.gradle.kts \
                        --replace-fail "gradlePluginPortal()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/plugins.gradle.org/m2\") }"
                    fi
                  fi
                  if [ -f packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts ]; then
                    if grep -q "google()" packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts; then
                      substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts \
                        --replace-fail "google()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2\") }"
                    fi
                    if grep -q "mavenCentral()" packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts; then
                      substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts \
                        --replace-fail "mavenCentral()" "maven { url = uri(\"$mitmOverlay\") }
          maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
                    fi
                    if grep -q "gradlePluginPortal()" packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts; then
                      substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts \
                        --replace-fail "gradlePluginPortal()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/plugins.gradle.org/m2\") }"
                    fi
                  fi
                fi
                if [ -f packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts ] && grep -q "pluginManagement {" packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts; then
                  substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts \
                    --replace-fail "pluginManagement {" "pluginManagement {
          resolutionStrategy {
            eachPlugin {
              if (requested.id.id == \"org.jetbrains.kotlin.jvm\") {
                useModule(\"org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24\")
              }
            }
          }"
                fi
                expoSharedGradle="packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/expo-autolinking-plugin-shared/build.gradle.kts"
                expoPluginGradle="packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/expo-autolinking-plugin/build.gradle.kts"
                expoSettingsGradle="packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/expo-autolinking-settings-plugin/build.gradle.kts"
                rnSharedGradle="packages/app-mobile/node_modules/@react-native/gradle-plugin/shared/build.gradle.kts"
                rnSettingsGradle="packages/app-mobile/node_modules/@react-native/gradle-plugin/settings-plugin/build.gradle.kts"
                for f in "$expoSharedGradle" "$expoPluginGradle" "$expoSettingsGradle"; do
                  if [ -f "$f" ] && grep -q "repositories {" "$f" && ! grep -q "gradlePluginPortal()" "$f"; then
                    substituteInPlace "$f" \
                      --replace-fail "repositories {" "repositories {
          gradlePluginPortal()"
                  fi
                done
                if [ -f "$rnSharedGradle" ] && ! grep -q "gradlePluginPortal()" "$rnSharedGradle"; then
                  if grep -q "repositories { mavenCentral() }" "$rnSharedGradle"; then
                    substituteInPlace "$rnSharedGradle" \
                      --replace-fail "repositories { mavenCentral() }" "repositories {
          gradlePluginPortal()
          mavenCentral()
        }"
                  elif grep -q "repositories {" "$rnSharedGradle"; then
                    substituteInPlace "$rnSharedGradle" \
                      --replace-fail "repositories {" "repositories {
          gradlePluginPortal()"
                  fi
                fi
                if [ -f "$rnSettingsGradle" ] && ! grep -q "gradlePluginPortal()" "$rnSettingsGradle"; then
                  if grep -q "repositories { mavenCentral() }" "$rnSettingsGradle"; then
                    substituteInPlace "$rnSettingsGradle" \
                      --replace-fail "repositories { mavenCentral() }" "repositories {
          gradlePluginPortal()
          mavenCentral()
        }"
                  elif grep -q "repositories {" "$rnSettingsGradle"; then
                    substituteInPlace "$rnSettingsGradle" \
                      --replace-fail "repositories {" "repositories {
          gradlePluginPortal()"
                  fi
                fi
                if [[ -z "''${IN_GRADLE_UPDATE_DEPS:-}" && -d "${finalAttrs.mitmCache}" ]]; then
                  for f in "$expoSharedGradle" "$expoPluginGradle" "$expoSettingsGradle" "$rnSharedGradle" "$rnSettingsGradle"; do
                    if [ -f "$f" ]; then
                      if grep -q "google()" "$f"; then
                        substituteInPlace "$f" \
                          --replace-fail "google()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2\") }"
                      fi
                      if grep -q "mavenCentral()" "$f"; then
                        substituteInPlace "$f" \
                          --replace-fail "mavenCentral()" "maven { url = uri(\"$mitmOverlay\") }
          maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
                      fi
                      if grep -q "gradlePluginPortal()" "$f"; then
                        substituteInPlace "$f" \
                          --replace-fail "gradlePluginPortal()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/plugins.gradle.org/m2\") }"
                      fi
                    fi
                  done
                  find packages/app-mobile -type f \( -name "*.gradle" -o -name "*.gradle.kts" -o -name "settings.gradle" -o -name "settings.gradle.kts" \) -print0 | while IFS= read -r -d "" f; do
                    if grep -q "google()" "$f"; then
                      substituteInPlace "$f" \
                        --replace-fail "google()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2\") }"
                    fi
                    if grep -q "mavenCentral()" "$f"; then
                      substituteInPlace "$f" \
                        --replace-fail "mavenCentral()" "maven { url = uri(\"$mitmOverlay\") }
          maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
                    fi
                    if grep -q "gradlePluginPortal()" "$f"; then
                      substituteInPlace "$f" \
                        --replace-fail "gradlePluginPortal()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/plugins.gradle.org/m2\") }"
                    fi
                  done
                fi
                if grep -q "from './rollup.config';" packages/turndown-plugin-gfm/config/rollup.config.cjs.js; then
                  substituteInPlace packages/turndown-plugin-gfm/config/rollup.config.cjs.js \
                    --replace-fail "from './rollup.config';" "from './rollup.config.js';"
                fi
                if grep -q "from './rollup.config';" packages/turndown-plugin-gfm/config/rollup.config.browser.cjs.js; then
                  substituteInPlace packages/turndown-plugin-gfm/config/rollup.config.browser.cjs.js \
                    --replace-fail "from './rollup.config';" "from './rollup.config.js';"
                fi
                ${nodejs}/bin/node -e "const fs=require('fs'); const path=require('path'); let d=process.cwd(); while (d !== path.dirname(d) && !fs.existsSync(path.join(d,'packages','app-mobile','package.json'))) d = path.dirname(d); const f=require(path.join(d,'packages','tools','compilePackageInfo.js')); Promise.resolve(f(path.join(d,'packages','app-mobile','package.json'), path.join(d,'packages','app-mobile','packageInfo.js'))).catch(e=>{console.error(e); process.exit(1);});"
                patchShebangs packages/turndown/node_modules/rollup/dist/bin
                patchShebangs packages/turndown-plugin-gfm/node_modules/.bin
                export PATH="$PWD/packages/turndown/node_modules/.bin:$PWD/packages/turndown-plugin-gfm/node_modules/.bin:$PATH"
                (cd packages/turndown && npm run build-cjs)
                (cd packages/turndown-plugin-gfm && ${nodejs}/bin/node ../turndown/node_modules/rollup/dist/bin/rollup -c config/rollup.config.cjs.js && ${nodejs}/bin/node ../turndown/node_modules/rollup/dist/bin/rollup -c config/rollup.config.browser.cjs.js)
                ${lib.getExe yarn-berry_4} workspace @joplin/whisper-voice-typing build
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

      buildPhase = ''
        runHook preBuild
        gradle --no-daemon $gradleBuildTask
        runHook postBuild
      '';

      dontNpmBuild = true;
      dontYarnBuild = true;

      gradleFlags = [
        "--project-dir"
        "packages/app-mobile/android"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless},${jdk21_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
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
