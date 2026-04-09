{
  androidSdkBuilder,
  fetchFromGitHub,
  gradle2nixBuilders,
  overrides-from-source,
  gradle-packages,
  jdk17_headless,
  lib,
  stdenv,
  writableTmpDirAsHomeHook,
  overrides-update,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-34
    s.build-tools-34-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.2";
      hash = "sha256-OPZs1u7yF7TDWFW7EepOn7xTWUzMy1+4Lf0xfvjCxaM=";
      defaultJava = jdk17_headless;
    }).wrapped;
in
gradle2nixBuilders.buildGradlePackage rec {
  pname = "zoomimage";
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "panpf";
    repo = "zoomimage";
    tag = version;
    hash = "sha256-MoQujZhZLReE9vSwiCOq/u/2g9sSeNX96vPwXcQcj0E=";
  };

  lockFile = ./gradle.lock;

  inherit gradle;

  overrides = overrides-from-source // overrides-update;

  buildJdk = jdk17_headless;

  nativeBuildInputs = [
    jdk17_headless
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk17_headless}" else "${jdk17_headless}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
  };

  postUnpack = ''
    cat >> "$sourceRoot/build.gradle.kts" <<'EOF'

    allprojects {
        if (hasProperty("versionName")
            && hasProperty("GROUP")
            && hasProperty("POM_ARTIFACT_ID")
        ) {
            apply(plugin = "com.vanniktech.maven.publish")

            configure<com.vanniktech.maven.publish.MavenPublishBaseExtension> {
                version = property("versionName").toString()
            }
        }
    }
    EOF

    substituteInPlace "$sourceRoot/gradle.properties" \
      --replace-fail 'RELEASE_SIGNING_ENABLED=true' 'RELEASE_SIGNING_ENABLED=false'
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "--console=plain"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${
      if stdenv.isDarwin then "${jdk17_headless}" else "${jdk17_headless}/lib/openjdk"
    }"
  ];

  gradleBuildFlags = [
    ":zoomimage-core:publishToMavenLocal"
    ":zoomimage-core-glide:publishToMavenLocal"
    ":zoomimage-view:publishToMavenLocal"
    ":zoomimage-view-glide:publishToMavenLocal"
  ];

  installPhase = ''
    runHook preInstall

    repoBase="$NIX_BUILD_TOP/.m2/repository/io/github/panpf/zoomimage"
    mkdir -p "$out"
    install -Dm644 "$repoBase/zoomimage-core-android/${version}/zoomimage-core-android-${version}.aar" "$out/zoomimage-core-android-${version}.aar"
    install -Dm644 "$repoBase/zoomimage-core-android/${version}/zoomimage-core-android-${version}.module" "$out/zoomimage-core-android-${version}.module"
    install -Dm644 "$repoBase/zoomimage-core-android/${version}/zoomimage-core-android-${version}.pom" "$out/zoomimage-core-android-${version}.pom"
    install -Dm644 "$repoBase/zoomimage-core-glide/${version}/zoomimage-core-glide-${version}.aar" "$out/zoomimage-core-glide-${version}.aar"
    install -Dm644 "$repoBase/zoomimage-core-glide/${version}/zoomimage-core-glide-${version}.module" "$out/zoomimage-core-glide-${version}.module"
    install -Dm644 "$repoBase/zoomimage-core-glide/${version}/zoomimage-core-glide-${version}.pom" "$out/zoomimage-core-glide-${version}.pom"
    install -Dm644 "$repoBase/zoomimage-view/${version}/zoomimage-view-${version}.aar" "$out/zoomimage-view-${version}.aar"
    install -Dm644 "$repoBase/zoomimage-view/${version}/zoomimage-view-${version}.module" "$out/zoomimage-view-${version}.module"
    install -Dm644 "$repoBase/zoomimage-view/${version}/zoomimage-view-${version}.pom" "$out/zoomimage-view-${version}.pom"
    install -Dm644 "$repoBase/zoomimage-view-glide/${version}/zoomimage-view-glide-${version}.aar" "$out/zoomimage-view-glide-${version}.aar"
    install -Dm644 "$repoBase/zoomimage-view-glide/${version}/zoomimage-view-glide-${version}.module" "$out/zoomimage-view-glide-${version}.module"
    install -Dm644 "$repoBase/zoomimage-view-glide/${version}/zoomimage-view-glide-${version}.pom" "$out/zoomimage-view-glide-${version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ZoomImage Android artifacts built from source";
    homepage = "https://github.com/panpf/zoomimage";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
