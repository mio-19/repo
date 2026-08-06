{
  stdenv,
  mk-apk-package,
  lib,
  jdk17_headless,
  gradle_8_14_3,
  buildGradlePackage,
  fetchgit,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-35-0-0
    s.build-tools-36-0-0
    s.ndk-27-3-13750724
    s.cmake-3-31-6
  ]);

  gradle_pkg = gradle_8_14_3;

  appPackage = stdenv.mkDerivation rec {
    pname = "vpnhotspot";
    version = "2.19.1";

    gradle = gradle_pkg;

    __darwinAllowLocalNetworking = true;

    gradleUpdateTask = ":mobile:assembleRelease";

    mitmCache = gradle.fetchDeps {
      pkg = appPackage;
      data = ./vpnhotspot_deps.json;
    };

    src = fetchgit {
      url = "https://github.com/Mygod/VPNHotspot.git";
      tag = "v${version}";
      hash = "sha256-706n9cGGZYxB3KG7/MWbsTfICfHJpaXygihBs+MeaGA=";
    };

    gradleBuildFlags = [ 
      ":mobile:assembleRelease" 
      "--no-daemon"
      "-Dorg.gradle.jvmargs=-Xmx2048m -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv6Addresses=false"
    ];
    
    nativeBuildInputs = [
      jdk17_headless
      gradle_pkg
      git
    ];

    preBuild = ''
      export ANDROID_HOME="${androidSdk}/share/android-sdk"
      export ANDROID_NDK_ROOT="${androidSdk}/share/android-sdk/ndk/27.3.13750724"
      export NDK_VERSION="27.3.13750724"
      export ANDROID_SDK_ROOT="$ANDROID_HOME"
      
      # Inject ndkVersion and buildToolsVersion since AGP has defaults that mismatch our SDK
      sed -i 's/android {/android { ndkVersion = "27.3.13750724"; buildToolsVersion = "36.0.0"; externalNativeBuild.cmake.version = "3.31.6"/' mobile/build.gradle.kts
      
      # Disable lint that crashes
      find . -name "build.gradle*" -exec sed -i 's/abortOnError true/abortOnError false/' {} + || true
      
      # Disable vcsInfo since Nix fetchgit removes .git
      sed -i 's/vcsInfo.include = true/vcsInfo.include = false/' mobile/build.gradle.kts

      # Disable R8 minify to avoid memory hangs during build
      sed -i 's/isMinifyEnabled = true/isMinifyEnabled = false/' mobile/build.gradle.kts
      sed -i 's/isShrinkResources = true/isShrinkResources = false/' mobile/build.gradle.kts

      # Prevent Gradle from forking a single-use daemon to honor gradle.properties JVM args
      if [ -f gradle.properties ]; then
        sed -i '/^org\.gradle\.jvmargs=/d' gradle.properties || true
      fi
      export GRADLE_OPTS="-Xmx2048m -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv6Addresses=false"
    '';

    gradleFlags = [
      "-xlintVitalRelease"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    ];

    installPhase = ''
      mkdir -p $out
      find . -name "*.apk" -type f -exec mv {} $out/ \;
    '';
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "mobile/build/outputs/apk/release/mobile-release-unsigned.apk";
  signScriptName = "vpnhotspot-sign";
}
