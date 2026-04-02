{
  mk-apk-package,
  lib,
  jdk21,
  jdk17_headless,
  gradle-packages,
  stdenv,
  ninja,
  git,
  fetchFromGitHub,
  yarn-berry_4,
  nodejs,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      gradle =
        (gradle-packages.mkGradle {
          version = "8.14.3";
          hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
          defaultJava = jdk21;
        }).wrapped;

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-31
        s.platforms-android-35
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-0-0
        s.cmake-3-31-6
        s.ndk-27-1-12297006
      ]);
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "joplin";
      version = "3.5.13";

      src = fetchFromGitHub {
        owner = "laurent22";
        repo = "joplin";
        tag = "v${finalAttrs.version}";
        hash = "sha256-KSunfdaT5K5Hk4D65Z4QFsLq9Z1jCoU5sWkypbjjmOA=";
      };

      sourceRoot = "${finalAttrs.src.name}";

      missingHashes = ./missing-hashes.json;

      offlineCache = yarn-berry_4.fetchYarnBerryDeps {
        inherit (finalAttrs)
          src
          missingHashes
          ;
        hash = "sha256-iDclcCwzgmKOMxO4ZdmPyTKPoGY24+6gm19E4+pCB50=";
      };

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = ''
        :app:assembleRelease
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
        jdk21
        jdk17_headless
        git
        nodejs
        yarn-berry_4.yarnBerryConfigHook
        ninja
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.1.12297006";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
        GRADLE_OPTS = "-Dorg.gradle.java.installations.auto-download=false -Dorg.gradle.java.installations.paths=${jdk17_headless},${jdk21}";
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
                substituteInPlace packages/app-mobile/android/app/build.gradle \
                  --replace-fail "            version '3.22.1'" "            version '3.31.6'"
                substituteInPlace packages/app-mobile/android/app/build.gradle \
                  --replace-fail "            signingConfig signingConfigs.release" "            signingConfig signingConfigs.debug"
                substituteInPlace packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts \
                  --replace-fail 'id("org.gradle.toolchains.foojay-resolver-convention").version("0.5.0")' ""
                if [[ -z "''${IN_GRADLE_UPDATE_DEPS:-}" && -d "${finalAttrs.mitmCache}" ]]; then
                  if grep -q "google()" packages/app-mobile/android/settings.gradle; then
                    substituteInPlace packages/app-mobile/android/settings.gradle \
                      --replace-fail "google()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2\") }"
                  fi
                  if grep -q "mavenCentral()" packages/app-mobile/android/settings.gradle; then
                    substituteInPlace packages/app-mobile/android/settings.gradle \
                      --replace-fail "mavenCentral()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
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
                      --replace-fail "mavenCentral()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
                  fi
                  if grep -q "google()" packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts; then
                    substituteInPlace packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts \
                      --replace-fail "google()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2\") }"
                  fi
                  if grep -q "mavenCentral()" packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts; then
                    substituteInPlace packages/app-mobile/node_modules/@react-native/gradle-plugin/settings.gradle.kts \
                      --replace-fail "mavenCentral()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
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
                        --replace-fail "mavenCentral()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
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
                        --replace-fail "mavenCentral()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
                    fi
                    if grep -q "gradlePluginPortal()" packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts; then
                      substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts \
                        --replace-fail "gradlePluginPortal()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/plugins.gradle.org/m2\") }"
                    fi
                  fi
                fi
                if grep -q "2.0.21" packages/app-mobile/node_modules/@react-native/gradle-plugin/build.gradle.kts; then
                  substituteInPlace packages/app-mobile/node_modules/@react-native/gradle-plugin/build.gradle.kts \
                    --replace-fail "2.0.21" "1.9.24"
                fi
                if grep -q '"1.9.24"' packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/build.gradle.kts; then
                  substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/build.gradle.kts \
                    --replace-fail '"1.9.24"' 'embeddedKotlinVersion'
                fi
                if grep -q 'kotlin("jvm") version embeddedKotlinVersion apply false' packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/build.gradle.kts; then
                  substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/build.gradle.kts \
                    --replace-fail 'kotlin("jvm") version embeddedKotlinVersion apply false' 'kotlin("jvm") version "1.9.24" apply false'
                fi
                if grep -q 'kotlin("jvm") apply false' packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/build.gradle.kts; then
                  substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/build.gradle.kts \
                    --replace-fail 'kotlin("jvm") apply false' 'kotlin("jvm") version "1.9.24" apply false'
                fi
                if grep -q '"2.0.21"' packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/build.gradle.kts; then
                  substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/build.gradle.kts \
                    --replace-fail '"2.0.21"' 'embeddedKotlinVersion'
                fi
                if grep -q "2.0.21" packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/build.gradle.kts; then
                  substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/build.gradle.kts \
                    --replace-fail "2.0.21" "1.9.24"
                fi
                if [ -f packages/app-mobile/node_modules/expo-modules-autolinking/android/gradle/libs.versions.toml ] && grep -q "2.0.21" packages/app-mobile/node_modules/expo-modules-autolinking/android/gradle/libs.versions.toml; then
                  substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/gradle/libs.versions.toml \
                    --replace-fail "2.0.21" "1.9.24"
                fi
                if [ -f packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/gradle/libs.versions.toml ] && grep -q "2.0.21" packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/gradle/libs.versions.toml; then
                  substituteInPlace packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/gradle/libs.versions.toml \
                    --replace-fail "2.0.21" "1.9.24"
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
                          --replace-fail "mavenCentral()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2\") }"
                      fi
                      if grep -q "gradlePluginPortal()" "$f"; then
                        substituteInPlace "$f" \
                          --replace-fail "gradlePluginPortal()" "maven { url = uri(\"${finalAttrs.mitmCache}/https/plugins.gradle.org/m2\") }"
                      fi
                    fi
                  done
                fi
                find packages/app-mobile/node_modules/expo-modules-autolinking/android -type f \( -name "*.kts" -o -name "*.gradle" -o -name "*.toml" \) -print0 | while IFS= read -r -d "" f; do
                  if grep -q "2.0.21" "$f"; then
                    substituteInPlace "$f" --replace-fail "2.0.21" "1.9.24"
                  fi
                done
                find packages/app-mobile -type f \( -name "*.kts" -o -name "*.gradle" -o -name "*.toml" \) -print0 | while IFS= read -r -d "" f; do
                  if grep -q "2.0.21" "$f"; then
                    substituteInPlace "$f" --replace-fail "2.0.21" "1.9.24"
                  fi
                done
                substituteInPlace packages/turndown-plugin-gfm/config/rollup.config.cjs.js \
                  --replace-fail "from './rollup.config';" "from './rollup.config.js';"
                substituteInPlace packages/turndown-plugin-gfm/config/rollup.config.browser.cjs.js \
                  --replace-fail "from './rollup.config';" "from './rollup.config.js';"
                ${nodejs}/bin/node -e "const fs=require('fs'); const path=require('path'); let d=process.cwd(); while (d !== path.dirname(d) && !fs.existsSync(path.join(d,'packages','app-mobile','package.json'))) d = path.dirname(d); const f=require(path.join(d,'packages','tools','compilePackageInfo.js')); Promise.resolve(f(path.join(d,'packages','app-mobile','package.json'), path.join(d,'packages','app-mobile','packageInfo.js'))).catch(e=>{console.error(e); process.exit(1);});"
                patchShebangs packages/turndown/node_modules/rollup/dist/bin
                patchShebangs packages/turndown-plugin-gfm/node_modules/.bin
                export PATH="$PWD/packages/turndown/node_modules/.bin:$PWD/packages/turndown-plugin-gfm/node_modules/.bin:$PATH"
                (cd packages/turndown && npm run build-cjs)
                (cd packages/turndown-plugin-gfm && ${nodejs}/bin/node ../turndown/node_modules/rollup/dist/bin/rollup -c config/rollup.config.cjs.js && ${nodejs}/bin/node ../turndown/node_modules/rollup/dist/bin/rollup -c config/rollup.config.browser.cjs.js)
                ${nodejs}/bin/node .yarn/releases/yarn-4.9.2.cjs tsc
                ${nodejs}/bin/node .yarn/releases/yarn-4.9.2.cjs workspace @joplin/app-mobile buildInjectedJs
                if [[ -n "''${IN_GRADLE_UPDATE_DEPS:-}" ]]; then
                  bootstrapDir="$(mktemp -d)"
                  cat > "$bootstrapDir/build.gradle" <<'EOF'
        repositories {
            google()
            mavenCentral()
        }

        configurations {
            bootstrap
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
                cd packages/app-mobile/android
      '';

      buildPhase = ''
        runHook preBuild
        expoPluginGradle="packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/build.gradle.kts"
        if [ -f "$expoPluginGradle" ]; then
          substituteInPlace "$expoPluginGradle" --replace-warn "2.0.21" "1.9.24"
          echo "Expo plugin kotlin lines after patch:"
          grep -n "org.jetbrains.kotlin.jvm\\|2.0.21\\|1.9.24" "$expoPluginGradle" || true
        fi
        gradle --no-daemon $gradleBuildTask
        runHook postBuild
      '';

      dontNpmBuild = true;
      dontYarnBuild = true;

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless},${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 \
          app/build/outputs/apk/release/app-release.apk \
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
