{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  androidSdkBuilder,
  jdk21_headless,
  writableTmpDirAsHomeHook,
  runCommand,
  jre_headless,
  makeWrapper,
  gradle_8_13,
  git,
}:
let
  version = "1.0.6";

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.platforms-android-37-0
    s.build-tools-36-0-0
    s.build-tools-37-0-0
    s.ndk-29-0-13113456
    s.cmake-3-31-6
  ]);

  gradle = gradle_8_13;

  common = stdenv.mkDerivation (finalAttrs: {
    pname = "npatch-clionly";
    inherit version;

    # Manager source was deleted upstream from v1.0.1+; only the CLI jar is
    # built here by targeting :jar:buildRelease instead of the root buildRelease
    # task (which also requires the closed-source manager module).
    src = fetchFromGitHub {
      owner = "7723mod";
      repo = "NPatch";
      tag = "v1.0.6";
      fetchSubmodules = true;
      hash = "sha256-3JPtO35CeRnXdZXmIMMt+ZkymUMX6qaJCMQqoJtAbtE=";
    };

    postPatch = ''
            substituteInPlace build.gradle.kts \
              --replace-fail 'val androidCompileNdkVersion by extra("29.0.13599879")' \
                'val androidCompileNdkVersion by extra("29.0.13113456")' || true

            substituteInPlace settings.gradle.kts \
              --replace-quiet '":manager",' "" || true

            substituteInPlace patch-loader/src/main/java/top/nkbe/npatch/loader/LSPLoader.java \
              --replace-quiet 'instance.attachFramework(vectorContext);' 'instance.attachFramework(vectorContext, () -> {});' || true

            for f in patch-loader/src/main/java/top/nkbe/npatch/loader/LSPLoader.java \
                     patch-loader/src/main/java/top/nkbe/npatch/service/IntegrApplicationService.java \
                     patch-loader/src/main/java/top/nkbe/npatch/service/RemoteApplicationService.java \
                     patch-loader/src/main/java/top/nkbe/npatch/service/NeoLocalApplicationService.java; do
              sed -i '/public boolean isLogMuted() throws RemoteException {/i \        public long registerHotReloadTarget(String s, long l, org.lsposed.lspd.service.IHotReloadTarget t) throws android.os.RemoteException {\n            return 0L;\n        }\n' "$f" || true
            done

            substituteInPlace meta-loader/src/main/java/top/nkbe/npatch/metaloader/LSPAppComponentFactoryStub.java \
              --replace-quiet 'var cl = Objects.requireNonNull' 'ClassLoader cl = Objects.requireNonNull' \
              --replace-quiet 'try (var is = cl.getResourceAsStream(Constants.CONFIG_ASSET_PATH);' 'try (java.io.InputStream is = cl.getResourceAsStream(Constants.CONFIG_ASSET_PATH);' \
              --replace-quiet 'var reader = new JsonReader' 'android.util.JsonReader reader = new JsonReader' \
              --replace-quiet 'var name = reader.nextName();' 'String name = reader.nextName();' \
              --replace-quiet 'var ipm = IPackageManager.Stub.asInterface' 'android.content.pm.IPackageManager ipm = IPackageManager.Stub.asInterface' \
              --replace-quiet 'try (var zip = new ZipFile' 'try (java.util.zip.ZipFile zip = new ZipFile' \
              --replace-quiet 'var is = zip.getInputStream' 'java.io.InputStream is = zip.getInputStream' \
              --replace-quiet 'var os = new ByteArrayOutputStream' 'java.io.ByteArrayOutputStream os = new ByteArrayOutputStream' \
              --replace-quiet 'try (var is = cl.getResourceAsStream(Constants.LOADER_DEX_ASSET_PATH);' 'try (java.io.InputStream is = cl.getResourceAsStream(Constants.LOADER_DEX_ASSET_PATH);' \
              --replace-quiet 'try (var is = soSourceApk != null' 'try (java.io.InputStream is = soSourceApk != null' \
              --replace-quiet 'try (var os = new FileOutputStream(soFile))' 'try (java.io.FileOutputStream os = new FileOutputStream(soFile))' \
              --replace-quiet 'var currentPackageName = ActivityThread.class.getDeclaredMethod("currentPackageName");' 'java.lang.reflect.Method currentPackageName = ActivityThread.class.getDeclaredMethod("currentPackageName");' \
              --replace-quiet 'var app = ActivityThread.currentApplication();' 'android.app.Application app = ActivityThread.currentApplication();' \
              --replace-quiet 'var info = app.getApplicationInfo();' 'android.content.pm.ApplicationInfo info = app.getApplicationInfo();' || true

            for f in $(find . -name "build.gradle.kts"); do
              substituteInPlace "$f" \
                --replace-quiet 'val androidSourceCompatibility: JavaVersion by rootProject.extra' 'val androidSourceCompatibility = JavaVersion.VERSION_21' \
                --replace-quiet 'val androidTargetCompatibility: JavaVersion by rootProject.extra' 'val androidTargetCompatibility = JavaVersion.VERSION_21' \
                --replace-quiet 'val androidCompileNdkVersion: String by rootProject.extra' 'val androidCompileNdkVersion = "29.0.13113456"' \
                --replace-quiet 'val verCode: Int by rootProject.extra' 'val verCode = 733' \
                --replace-quiet 'val verName: String by rootProject.extra' 'val verName = "1.0.6"' \
                --replace-quiet 'val apiCode: Int by rootProject.extra' 'val apiCode = 102' \
                --replace-quiet 'val coreVerCode: Int by rootProject.extra' 'val coreVerCode = 10005' \
                --replace-quiet 'val coreVerName: String by rootProject.extra' 'val coreVerName = "1.0.6"' \
                --replace-quiet 'val defaultManagerPackageName: String by rootProject.extra' 'val defaultManagerPackageName = "top.nkbe.npatch"' \
                --replace-quiet 'rootProject.extra["apiCode"]' '102' \
                --replace-quiet 'rootProject.extra["defaultManagerPackageName"]' '"top.nkbe.npatch"' \
                --replace-quiet 'rootProject.extra["coreVerCode"]' '10005' \
                --replace-quiet 'rootProject.extra["coreVerName"]' '"1.0.6"' \
                --replace-quiet 'rootProject.extra["verCode"]' '733' \
                --replace-quiet 'rootProject.extra["verName"]' '"1.0.6"' \
                --replace-quiet 'arguments += "-DEXTERNAL_ROOT=''${File(rootDir.absolutePath, "core/external") }"' 'arguments += "-DEXTERNAL_ROOT=''${File(rootDir.absolutePath, "core/external") }"
                      arguments += "-DVECTOR_ROOT=''${File(rootDir.absolutePath, "core") }"' \
                --replace-quiet 'android {' 'android {
          compileSdk = 37
          ndkVersion = "29.0.13113456"
          buildToolsVersion = "37.0.0"
          compileOptions {
              sourceCompatibility = JavaVersion.VERSION_21
              targetCompatibility = JavaVersion.VERSION_21
          }
          defaultConfig {
              minSdk = 28
              targetSdk = 37
          }'
            done
            substituteInPlace build.gradle.kts \
              --replace-fail 'val verCode by extra(commitCount)' \
                'val verCode by extra(10005)' || true

            substituteInPlace patch-loader/src/main/java/top/nkbe/npatch/loader/LSPApplication.java \
              --replace-fail 'XposedBridge.setLogPrinter' '// XposedBridge.setLogPrinter' || true

            substituteInPlace patch-loader/src/main/java/top/nkbe/npatch/loader/LSPLoader.java \
              --replace-fail 'if (NativeAPI.initializeNativeEntrypoint(libName, candidate)) {' \
                             'if (false) {' || true

            printf '\n' >> build.gradle.kts
            cat >> build.gradle.kts <<'EOF'
            allprojects {
                configurations.configureEach {
                    resolutionStrategy.eachDependency {
                        if (requested.group == "androidx.savedstate"
                            && (requested.name == "savedstate-android" || requested.name == "savedstate-compose-android")
                            && (requested.version == "1.3.0" || requested.version == "1.3.1")
                        ) {
                            useVersion("1.3.3")
                            because("pin savedstate artifacts to versions present in offline lockfile")
                        }
                        // commons-lang3 3.14+ made MemberUtils methods private; pin to last compatible version
                        if (requested.group == "org.apache.commons" && requested.name == "commons-lang3") {
                            useVersion("3.13.0")
                            because("Vector core MemberUtilsX needs package-private MemberUtils API from 3.13.0")
                        }
                    }
                }
            }
      EOF

            # AGP calls git during configuration; init a dummy repo so it doesn't fail
            git init
            git config user.email "nix@build"
            git config user.name "Nix"
            git commit --allow-empty -m "init"
    '';

    # Build only the jar subproject — avoids the closed-source manager module
    gradleBuildTask = ":jar:buildRelease";
    gradleUpdateTask = finalAttrs.gradleBuildTask;

    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./npatch_clionly_deps.json;
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
      ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/29.0.13113456";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$PWD/.android"
      export GRADLE_USER_HOME="$PWD/.gradle"
      mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"

      echo "sdk.dir=$ANDROID_HOME" > local.properties
      echo "ndk.dir=$ANDROID_NDK_ROOT" >> local.properties
      cat >> gradle.properties <<EOF
      org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g
      android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.0.0/aapt2
      org.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.0.0/aapt2
      android.sdk.download=false
      EOF
    '';

    gradleFlags = [
      "--no-daemon"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    ];

    installPhase = ''
      runHook preInstall

      jar_path=$(find out/release -name "jar-v*.jar" | head -1)
      test -f "$jar_path"
      install -Dm644 "$jar_path" "$out/lspatch.jar"

      runHook postInstall
    '';

    meta = with lib; {
      description = "NPatch CLI tool built from source (v1.0.5, manager excluded)";
      homepage = "https://github.com/7723mod/NPatch";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
    };
  });
in
{
  inherit common;

  cli =
    runCommand "npatch-cli-${version}"
      {
        nativeBuildInputs = [ makeWrapper ];
        meta = with lib; {
          description = "NPatch CLI";
          homepage = "https://github.com/7723mod/NPatch";
          license = licenses.gpl3Only;
          platforms = platforms.unix;
          mainProgram = "npatch";
        };
      }
      ''
        mkdir -p $out/bin
        makeWrapper ${lib.getExe jre_headless} "$out/bin/npatch" --add-flags -jar --add-flags "${common}/lspatch.jar"
      '';
}
