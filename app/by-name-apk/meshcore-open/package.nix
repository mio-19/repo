{
  mk-apk-package,
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  flutter338,
  jdk17_headless,
  python3,
  gradle-packages,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.platforms-android-36
        # AGP may resolve aapt2 from build-tools 35.0.0 even with compileSdk 36.
        s.build-tools-35-0-0
        s.build-tools-36-0-0
        # Flutter 3.38.x defaults to ndkVersion = "28.2.13676358" in FlutterExtension.kt; override below
        s.ndk-29-0-14206865
        s.cmake-3-31-6
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.12";
          hash = "sha256-egDVH7kxR4Gaq3YCT+7OILa4TkIGlBAfJ2vpUuCL7wM=";
          defaultJava = jdk17_headless;
        }).wrapped;

      pythonWithYaml = python3.withPackages (ps: [ ps.pyyaml ]);
    in
    buildDartApplication.override { dart = flutter338; } (finalAttrs: {
      pname = "meshcore-open";
      version = "7.0.0+8";

      src = fetchFromGitHub {
        owner = "zjs81";
        repo = "meshcore-open";
        rev = "Alpha7";
        hash = "sha256-7szV0z9E/5Jb3Pyo3EFrzbB9mHIoJBgeqrnRdGko+PA=";
      };

      pubspecLock = lib.importJSON ./pubspec.lock.json;

      gitHashes = {
        flserial = "sha256-+v8++zKQkhI4KKyaiE14RxC/kCE96EMFVW4h7914cC0=";
      };

      sdkSourceBuilders = {
        flutter =
          name:
          runCommand "flutter-sdk-${name}" { passthru.packageRoot = "."; } ''
            for path in \
              '${flutter338}/packages/${name}' \
              '${flutter338}/bin/cache/pkg/${name}'; do
              if [ -d "$path" ]; then
                ln -s "$path" "$out"
                break
              fi
            done
            if [ ! -e "$out" ]; then
              echo 1>&2 'The Flutter SDK does not contain the requested package: ${name}!'
              exit 1
            fi
          '';
      };

      # MITM cache for offline Gradle/Maven dependency resolution (including
      # Gradle Plugin Portal requests for Kotlin and AGP plugins).
      # To regenerate after a version bump:
      #   nix build --impure .#meshcore-open.mitmCache.updateScript
      #   Run the resulting fetch-deps.sh from the repo root.
      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./meshcore-open_deps.json;
        silent = false;
        useBwrap = false;
      };

      gradleUpdateTask = ":app:assembleRelease :flserial:extractReleaseAnnotations";

      dontDartBuild = true;
      dontDartInstall = true;

      nativeBuildInputs = [
        gradle
        jdk17_headless
        python3
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };

      sdkSetupScript = ''
        flutter config --no-analytics >/dev/null 2>&1 || true
      '';

      # Flags used by the gradle() shell function in the fetchDeps update run.
      gradleFlags = [
        "-xlintVitalRelease"
        "--project-dir"
        "android"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

      postPatch = ''
        # Copy the full Flutter SDK to a writable location so included builds under
        # packages/flutter_tools/gradle can compile and write outputs.
        cp -LR ${flutter338} flutter-sdk
        chmod -R u+w flutter-sdk

        cat > android/gradle-version-normalize.init.gradle << 'INIT_SCRIPT'
        allprojects {
          buildscript {
            configurations.matching { it.name == "classpath" }.all {
              resolutionStrategy.eachDependency { details ->
                if (details.requested.group == "com.android.tools.build" && details.requested.name == "gradle") {
                  details.useVersion("8.9.1")
                }
              }
            }
          }
          configurations.configureEach {
            resolutionStrategy.eachDependency { details ->
              if (details.requested.group == "androidx.annotation" && details.requested.name == "annotation") {
                details.useVersion("1.8.0")
              }
              if (details.requested.group == "androidx.core" && details.requested.name == "core") {
                details.useVersion("1.13.1")
              }
              if (details.requested.group == "androidx.core" && details.requested.name == "core-ktx") {
                details.useVersion("1.13.1")
              }
            }
          }
        }
        INIT_SCRIPT

        # Replace the Gradle wrapper with our pinned Gradle binary.
        cat > android/gradlew << 'GRADLEW_SCRIPT'
        #!/bin/sh
        exec ${gradle}/bin/gradle -I "$PWD/gradle-version-normalize.init.gradle" "$@"
        GRADLEW_SCRIPT
        chmod +x android/gradlew
        substituteInPlace android/app/build.gradle.kts \
          --replace-fail 'ndkVersion = flutter.ndkVersion' 'ndkVersion = "29.0.14206865"'

        if grep -Fq 'android.newDsl=true' android/gradle.properties; then
          substituteInPlace android/gradle.properties \
            --replace-fail 'android.newDsl=true' 'android.newDsl=false'
        elif ! grep -Fq 'android.newDsl=' android/gradle.properties; then
          echo 'android.newDsl=false' >> android/gradle.properties
        fi

        cat >> android/app/build.gradle.kts << 'EOF'
        android {
          lint {
            checkReleaseBuilds = false
            abortOnError = false
          }
        }
        EOF
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        # local.properties is read by settings.gradle.kts (flutter.sdk) and AGP (sdk.dir).
        echo "sdk.dir=${androidSdk}/share/android-sdk" > android/local.properties
        echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.31.6" >> android/local.properties
        echo "flutter.sdk=$PWD/flutter-sdk" >> android/local.properties
      '';

      preBuild = ''
        # Propagate MITM proxy and toolchain settings to JVM instances invoked by
        # Flutter's internal Gradle calls (via android/gradlew).  The gradle setup
        # hook writes proxy flags to gradleFlagsArray for the gradle() shell function,
        # but Flutter calls gradlew directly.  GRADLE_OPTS is forwarded to the JVM.
        GRADLE_OPTS="''${GRADLE_OPTS:-}"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.auto-download=false"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.paths=${jdk17_headless}"
        GRADLE_OPTS="$GRADLE_OPTS -Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        if [[ -n "''${MITM_CACHE_KEYSTORE:-}" ]]; then
          GRADLE_OPTS="$GRADLE_OPTS -Dhttp.proxyHost=$MITM_CACHE_HOST"
          GRADLE_OPTS="$GRADLE_OPTS -Dhttp.proxyPort=$MITM_CACHE_PORT"
          GRADLE_OPTS="$GRADLE_OPTS -Dhttps.proxyHost=$MITM_CACHE_HOST"
          GRADLE_OPTS="$GRADLE_OPTS -Dhttps.proxyPort=$MITM_CACHE_PORT"
          GRADLE_OPTS="$GRADLE_OPTS -Djavax.net.ssl.trustStore=$MITM_CACHE_KEYSTORE"
          GRADLE_OPTS="$GRADLE_OPTS -Djavax.net.ssl.trustStorePassword=$MITM_CACHE_KS_PWD"
        fi
        export FLUTTER_ROOT="$PWD/flutter-sdk"
        export GRADLE_OPTS

        mkdir -p .dart-patched

        clone_dart_package() {
          local source_dir="$1"
          local patched_name="$2"
          local patched_dir="$PWD/.dart-patched/$patched_name"

          cp -LR "$source_dir" "$patched_dir"
          chmod -R u+w "$patched_dir"
          printf '%s\n' "$patched_dir"
        }

        replace_dart_package_root() {
          local original_dir="$1"
          local patched_dir="$2"

          substituteInPlace .dart_tool/package_config.json \
            --replace-fail "$original_dir" "$patched_dir"
        }

        replace_flutter_plugin_root() {
          local original_dir="$1"
          local patched_dir="$2"

          if [ -f .flutter-plugins-dependencies ] && grep -Fq "$original_dir" .flutter-plugins-dependencies; then
            substituteInPlace .flutter-plugins-dependencies \
              --replace-fail "$original_dir" "$patched_dir"
          fi

          if [ -f .flutter-plugins ] && grep -Fq "$original_dir" .flutter-plugins; then
            substituteInPlace .flutter-plugins \
              --replace-fail "$original_dir" "$patched_dir"
          fi
        }

        ${python3}/bin/python3 - <<'PY' > dart_package_dirs.sh
        import json
        import shlex
        import urllib.parse

        with open(".dart_tool/package_config.json") as f:
            data = json.load(f)

        wanted = {
            "flserial": "FLSERIAL_DIR",
        }

        found = {env_name: "" for env_name in wanted.values()}
        for pkg in data["packages"]:
            env_name = wanted.get(pkg["name"])
            if env_name:
                found[env_name] = urllib.parse.urlparse(pkg["rootUri"]).path.removesuffix("/.")

        for env_name, path in found.items():
            print(f"export {env_name}={shlex.quote(path)}")
        PY
        . ./dart_package_dirs.sh

        if [ -n "$FLSERIAL_DIR" ]; then
          patched_flserial_dir="$(clone_dart_package "$FLSERIAL_DIR" flserial)"
          substituteInPlace "$patched_flserial_dir/android/build.gradle" \
            --replace-fail 'classpath("com.android.tools.build:gradle:8.13.0")' \
              'classpath("com.android.tools.build:gradle:8.9.1")'
          replace_dart_package_root "$FLSERIAL_DIR" "$patched_flserial_dir"
        fi

        patch_plugin_gradle_file() {
          local gradle_file="$1"
          local target_agp='8.9.1'
          local target_kotlin='1.9.20'
          local old_value

          [ -f "$gradle_file" ] || return 0

          while IFS= read -r old_value; do
            [ "$old_value" = "com.android.tools.build:gradle:$target_agp" ] && continue
            substituteInPlace "$gradle_file" \
              --replace-fail "$old_value" "com.android.tools.build:gradle:$target_agp"
          done < <(grep -oE 'com\.android\.tools\.build:gradle:[0-9.]+' "$gradle_file" | sort -u)

          while IFS= read -r old_value; do
            [ "$old_value" = "org.jetbrains.kotlin:kotlin-gradle-plugin:$target_kotlin" ] && continue
            substituteInPlace "$gradle_file" \
              --replace-fail "$old_value" "org.jetbrains.kotlin:kotlin-gradle-plugin:$target_kotlin"
          done < <(grep -oE 'org\.jetbrains\.kotlin:kotlin-gradle-plugin:[0-9.]+' "$gradle_file" | sort -u)

          while IFS= read -r old_value; do
            [ -n "$old_value" ] || continue
            substituteInPlace "$gradle_file" \
              --replace-fail "$old_value" "ext.kotlin_version = '$target_kotlin'"
          done < <(grep -oE "ext\\.kotlin_version = '[0-9.]+'" "$gradle_file" | sort -u)

          while IFS= read -r old_value; do
            case "$old_value" in
              "id(\"com.android.application\") version \"$target_agp\"" | "id(\"com.android.library\") version \"$target_agp\"" | "id(\"com.android.test\") version \"$target_agp\"" )
                continue
                ;;
            esac
            substituteInPlace "$gradle_file" \
              --replace-fail "$old_value" "''${old_value% version *} version \"$target_agp\""
          done < <(grep -oE 'id\("com\.android\.(application|library|test)"\) version "[0-9.]+"' "$gradle_file" | sort -u)

          while IFS= read -r old_value; do
            case "$old_value" in
              "id \"com.android.application\" version \"$target_agp\"" | "id \"com.android.library\" version \"$target_agp\"" | "id \"com.android.test\" version \"$target_agp\"" )
                continue
                ;;
            esac
            substituteInPlace "$gradle_file" \
              --replace-fail "$old_value" "''${old_value% version *} version \"$target_agp\""
          done < <(grep -oE 'id "com\.android\.(application|library|test)" version "[0-9.]+"' "$gradle_file" | sort -u)

          while IFS= read -r old_value; do
            case "$old_value" in
              "id 'com.android.application' version '$target_agp'" | "id 'com.android.library' version '$target_agp'" | "id 'com.android.test' version '$target_agp'" )
                continue
                ;;
            esac
            substituteInPlace "$gradle_file" \
              --replace-fail "$old_value" "''${old_value% version *} version '$target_agp'"
          done < <(grep -oE "id 'com\\.android\\.(application|library|test)' version '[0-9.]+'" "$gradle_file" | sort -u)

          while IFS= read -r old_value; do
            case "$old_value" in
              "id(\"org.jetbrains.kotlin.android\") version \"$target_kotlin\"" | "id(\"org.jetbrains.kotlin.jvm\") version \"$target_kotlin\"" )
                continue
                ;;
            esac
            substituteInPlace "$gradle_file" \
              --replace-fail "$old_value" "''${old_value% version *} version \"$target_kotlin\""
          done < <(grep -oE 'id\("org\.jetbrains\.kotlin\.(android|jvm)"\) version "[0-9.]+"' "$gradle_file" | sort -u)

          while IFS= read -r old_value; do
            case "$old_value" in
              "id \"org.jetbrains.kotlin.android\" version \"$target_kotlin\"" | "id \"org.jetbrains.kotlin.jvm\" version \"$target_kotlin\"" )
                continue
                ;;
            esac
            substituteInPlace "$gradle_file" \
              --replace-fail "$old_value" "''${old_value% version *} version \"$target_kotlin\""
          done < <(grep -oE 'id "org\.jetbrains\.kotlin\.(android|jvm)" version "[0-9.]+"' "$gradle_file" | sort -u)

          while IFS= read -r old_value; do
            case "$old_value" in
              "id 'org.jetbrains.kotlin.android' version '$target_kotlin'" | "id 'org.jetbrains.kotlin.jvm' version '$target_kotlin'" )
                continue
                ;;
            esac
            substituteInPlace "$gradle_file" \
              --replace-fail "$old_value" "''${old_value% version *} version '$target_kotlin'"
          done < <(grep -oE "id 'org\\.jetbrains\\.kotlin\\.(android|jvm)' version '[0-9.]+'" "$gradle_file" | sort -u)

          while IFS= read -r old_value; do
            [ "$old_value" = "kotlin_version = '$target_kotlin'" ] && continue
            substituteInPlace "$gradle_file" \
              --replace-fail "$old_value" "kotlin_version = '$target_kotlin'"
          done < <(grep -oE "kotlin_version = '[0-9.]+'" "$gradle_file" | sort -u)

          if grep -Fq '27.0.12077973' "$gradle_file"; then
            substituteInPlace "$gradle_file" \
              --replace-fail '27.0.12077973' '29.0.14206865'
          fi
          if grep -Fq '28.2.13676358' "$gradle_file"; then
            substituteInPlace "$gradle_file" \
              --replace-fail '28.2.13676358' '29.0.14206865'
          fi

          if ! grep -Fq 'nixDisableReleaseLint' "$gradle_file"; then
            if [[ "$gradle_file" == *.gradle.kts ]]; then
              cat >> "$gradle_file" <<'EOF'
        // nixDisableReleaseLint
        android {
          lint {
            checkReleaseBuilds = false
            abortOnError = false
          }
        }
        EOF
            else
              cat >> "$gradle_file" <<'EOF'
        // nixDisableReleaseLint
        android {
          lintOptions {
            checkReleaseBuilds false
            abortOnError false
          }
          lint {
            checkReleaseBuilds false
            abortOnError false
          }
        }
        EOF
            fi
          fi
        }

        patch_ndk_version_file() {
          local file="$1"
          [ -f "$file" ] || return 0

          if grep -Fq '27.0.12077973' "$file"; then
            substituteInPlace "$file" \
              --replace-fail '27.0.12077973' '29.0.14206865'
          fi
          if grep -Fq '28.2.13676358' "$file"; then
            substituteInPlace "$file" \
              --replace-fail '28.2.13676358' '29.0.14206865'
          fi
          if grep -Fq 'android.newDsl=true' "$file"; then
            substituteInPlace "$file" \
              --replace-fail 'android.newDsl=true' 'android.newDsl=false'
          fi
        }

        declare -A patched_pkg_dirs

        ${pythonWithYaml}/bin/python3 ${../_shared/generate-flutter-plugins.py}

        while IFS= read -r plugin_dir; do
          [ -n "$plugin_dir" ] || continue
          work_plugin_dir="$plugin_dir"
          if [[ "$plugin_dir" == /nix/store/* ]]; then
            if [ -z "''${patched_pkg_dirs[$plugin_dir]:-}" ]; then
              patched_pkg_dirs[$plugin_dir]="$(clone_dart_package "$plugin_dir" "$(basename "$plugin_dir")")"
              if grep -Fq "$plugin_dir" .dart_tool/package_config.json; then
                replace_dart_package_root "$plugin_dir" "''${patched_pkg_dirs[$plugin_dir]}"
              fi
              replace_flutter_plugin_root "$plugin_dir" "''${patched_pkg_dirs[$plugin_dir]}"
            fi
            work_plugin_dir="''${patched_pkg_dirs[$plugin_dir]}"
          fi
          if [ -d "$work_plugin_dir/android" ]; then
            while IFS= read -r gradle_file; do
              patch_plugin_gradle_file "$gradle_file"
            done < <(find "$work_plugin_dir/android" -type f \( -name '*.gradle' -o -name '*.gradle.kts' \))
          fi
          if [ -f "$work_plugin_dir/gradle.properties" ]; then
            patch_ndk_version_file "$work_plugin_dir/gradle.properties"
          fi
          if [ -d "$work_plugin_dir/android" ]; then
            while IFS= read -r ndk_file; do
              patch_ndk_version_file "$ndk_file"
            done < <(find "$work_plugin_dir/android" -type f \( -name '*.gradle' -o -name '*.gradle.kts' -o -name '*.properties' \))
          fi
        done < <(${python3}/bin/python3 - <<'PY'
        import json

        with open(".flutter-plugins-dependencies") as f:
            data = json.load(f)
        for plugin in data.get("plugins", {}).get("android", []):
            path = plugin.get("path", "")
            if path:
                print(path)
        PY
        )
      '';

      buildPhase = ''
        runHook preBuild
        flutter build apk --release --no-pub
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 build/app/outputs/flutter-apk/app-release.apk \
          "$out/meshcore-open.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "MeshCore Open Android client built from source";
        homepage = "https://github.com/zjs81/meshcore-open";
        license = licenses.mit;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "meshcore-open.apk";
  signScriptName = "sign-meshcore-open";
  fdroid = {
    appId = "com.meshcore.meshcore_open";
    metadataYml = ''
      Categories:
        - Internet
      License: MIT
      SourceCode: https://github.com/zjs81/meshcore-open
      IssueTracker: https://github.com/zjs81/meshcore-open/issues
      AutoName: MeshCore Open
      Summary: Mesh networking client for MeshCore devices
      Description: |-
        MeshCore Open is an open-source client for MeshCore LoRa mesh
        networking devices, supporting messaging, channels, maps, and
        device management.
    '';
  };
}
