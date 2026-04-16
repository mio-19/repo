{
  gradle_5_6_4,
  jdk11_headless,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
}:
let
  gradle = gradle_5_6_4;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gradle-unwrapped";
  version = "6.0-rc-1";

  src = fetchFromGitHub {
    owner = "gradle";
    repo = "gradle";
    tag = "v6.0.0-RC1";
    hash = "sha256-3LKrdYx7kfasoJ3A911C17fmAw3507W7qAqiKraoOSU=";
  };

  gradleBuildTask = ":distributions-full:binDistributionZip";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  nativeBuildInputs = [
    gradle
    makeWrapper
    jdk11_headless
  ];

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
    silent = false;
    useBwrap = false;
  };

  __darwinAllowLocalNetworking = true;

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk11_headless}" else "${jdk11_headless}/lib/openjdk";
  };

  preBuild = ''
    export HOME="$PWD/.home"
    mkdir -p "$HOME"
    echo "org.gradle.jvmargs=" >> gradle.properties
    export GRADLE_OPTS="-Dorg.gradle.jvmargs="
  '';

  gradleFlags = [
    "-PfinalRelease=true"
    "--no-daemon"
    "--no-build-cache"
    "-Dorg.gradle.vfs.watch=false"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  postPatch = ''
    rm -f gradle/verification-metadata.xml
    rm -fr gradle/wrapper .teamcity/.mvn/wrapper
    find . -name "*.jar" -print0 | xargs -0 rm -f
  '';

  installPhase = ''
    runHook preInstall

    dist_zip="$(find . -path '*/build/distributions/gradle-*-bin.zip' | grep '/distributions-full/' | head -n1)"
    test -n "$dist_zip"
    test -f "$dist_zip"

    mkdir dist-unpack
    unzip -q "$dist_zip" -d dist-unpack
    cd dist-unpack/gradle-*

    mkdir -p "$out/libexec/gradle" "$out/bin"
    mv lib "$out/libexec/gradle/"
    mv bin "$out/libexec/gradle/"

    makeWrapper "$out/libexec/gradle/bin/gradle" "$out/bin/gradle" \
      --set-default JAVA_HOME "${finalAttrs.env.JAVA_HOME}"

    runHook postInstall
  '';
})
