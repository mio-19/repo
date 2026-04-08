{
  androidSdkBuilder,
  fetchFromGitHub,
  gradle-packages,
  jdk17,
  lib,
  stdenv,
  writableTmpDirAsHomeHook,
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
      defaultJava = jdk17;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zoomimage";
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "panpf";
    repo = "zoomimage";
    tag = finalAttrs.version;
    hash = "sha256-MoQujZhZLReE9vSwiCOq/u/2g9sSeNX96vPwXcQcj0E=";
  };

  gradleBuildTask = ":zoomimage-core:publishToMavenLocal :zoomimage-core-glide:publishToMavenLocal :zoomimage-view:publishToMavenLocal :zoomimage-view-glide:publishToMavenLocal";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "zoomimage";
    pkg = finalAttrs.finalPackage;
    data = ./zoomimage_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk17
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk17}" else "${jdk17}/lib/openjdk";
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
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  installPhase = ''
    runHook preInstall

    repoBase="$NIX_BUILD_TOP/.m2/repository/io/github/panpf/zoomimage"
    mkdir -p "$out"
    install -Dm644 "$repoBase/zoomimage-core-android/${finalAttrs.version}/zoomimage-core-android-${finalAttrs.version}.aar" "$out/zoomimage-core-android-${finalAttrs.version}.aar"
    install -Dm644 "$repoBase/zoomimage-core-android/${finalAttrs.version}/zoomimage-core-android-${finalAttrs.version}.module" "$out/zoomimage-core-android-${finalAttrs.version}.module"
    install -Dm644 "$repoBase/zoomimage-core-android/${finalAttrs.version}/zoomimage-core-android-${finalAttrs.version}.pom" "$out/zoomimage-core-android-${finalAttrs.version}.pom"
    install -Dm644 "$repoBase/zoomimage-core-glide/${finalAttrs.version}/zoomimage-core-glide-${finalAttrs.version}.aar" "$out/zoomimage-core-glide-${finalAttrs.version}.aar"
    install -Dm644 "$repoBase/zoomimage-core-glide/${finalAttrs.version}/zoomimage-core-glide-${finalAttrs.version}.module" "$out/zoomimage-core-glide-${finalAttrs.version}.module"
    install -Dm644 "$repoBase/zoomimage-core-glide/${finalAttrs.version}/zoomimage-core-glide-${finalAttrs.version}.pom" "$out/zoomimage-core-glide-${finalAttrs.version}.pom"
    install -Dm644 "$repoBase/zoomimage-view/${finalAttrs.version}/zoomimage-view-${finalAttrs.version}.aar" "$out/zoomimage-view-${finalAttrs.version}.aar"
    install -Dm644 "$repoBase/zoomimage-view/${finalAttrs.version}/zoomimage-view-${finalAttrs.version}.module" "$out/zoomimage-view-${finalAttrs.version}.module"
    install -Dm644 "$repoBase/zoomimage-view/${finalAttrs.version}/zoomimage-view-${finalAttrs.version}.pom" "$out/zoomimage-view-${finalAttrs.version}.pom"
    install -Dm644 "$repoBase/zoomimage-view-glide/${finalAttrs.version}/zoomimage-view-glide-${finalAttrs.version}.aar" "$out/zoomimage-view-glide-${finalAttrs.version}.aar"
    install -Dm644 "$repoBase/zoomimage-view-glide/${finalAttrs.version}/zoomimage-view-glide-${finalAttrs.version}.module" "$out/zoomimage-view-glide-${finalAttrs.version}.module"
    install -Dm644 "$repoBase/zoomimage-view-glide/${finalAttrs.version}/zoomimage-view-glide-${finalAttrs.version}.pom" "$out/zoomimage-view-glide-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ZoomImage Android artifacts built from source";
    homepage = "https://github.com/panpf/zoomimage";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
