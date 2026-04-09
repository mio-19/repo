{
  androidSdkBuilder,
  fetchFromGitHub,
  git,
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
    s.build-tools-33-0-1
    s.platforms-android-36
    s.build-tools-36-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.14.3";
      hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
      defaultJava = jdk17;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "glide";
  version = "5.0.5";

  src = fetchFromGitHub {
    owner = "bumptech";
    repo = "glide";
    tag = "v${finalAttrs.version}";
    hash = "sha256-UTqNCXnbhgmN6gW0F79uQ4lBQICCMGYQPjh42DJ4+pM=";
  };

  gradleBuildTask = ":library:publishToMavenLocal :third_party:gif_decoder:publishToMavenLocal :third_party:disklrucache:publishToMavenLocal";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "glide";
    pkg = finalAttrs.finalPackage;
    data = ./glide_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    git
    jdk17
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk17}" else "${jdk17}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
  };

  postUnpack = ''
        substituteInPlace "$sourceRoot/settings.gradle" \
          --replace-fail 'exec {
        commandLine "git", "submodule", "update", "--init", "--recursive"
        ignoreExitValue true
    }
    ' ""

        substituteInPlace "$sourceRoot/annotation/ksp/build.gradle" \
          --replace-fail 'JavaLanguageVersion.of(11)' 'JavaLanguageVersion.of(17)'
        substituteInPlace "$sourceRoot/annotation/ksp/test/build.gradle" \
          --replace-fail 'JavaLanguageVersion.of(11)' 'JavaLanguageVersion.of(17)'
        substituteInPlace "$sourceRoot/annotation/ksp/integrationtest/build.gradle" \
          --replace-fail 'JavaLanguageVersion.of(11)' 'JavaLanguageVersion.of(17)'
        substituteInPlace "$sourceRoot/samples/gallery/build.gradle" \
          --replace-fail 'JavaLanguageVersion.of(11)' 'JavaLanguageVersion.of(17)'

        substituteInPlace "$sourceRoot/scripts/upload.gradle.kts" \
          --replace-fail '  "signAllPublications"()
    ' ""

    printf '\n%s\n' \
      'tasks.matching { it.name == "javaDocReleaseGeneration" }.configureEach {' \
      '    enabled = false' \
      '}' \
      'tasks.matching { it.name == "javaDocReleaseJar" }.configureEach {' \
      '    setDependsOn([])' \
      '    from([])' \
      '}' >> "$sourceRoot/library/build.gradle"
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  ''
  + lib.optionalString stdenv.isDarwin ''
    export MAVEN_OPTS="-Dmaven.repo.local=$HOME/.m2/repository"
    mkdir -p "$HOME/.m2/repository"
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  installPhase = ''
    runHook preInstall

    repoBase="${
      if stdenv.isDarwin then "$HOME" else "$NIX_BUILD_TOP"
    }/.m2/repository/com/github/bumptech/glide"
    mkdir -p "$out"
    install -Dm644 "$repoBase/glide/${finalAttrs.version}/glide-${finalAttrs.version}.aar" "$out/glide-${finalAttrs.version}.aar"
    install -Dm644 "$repoBase/glide/${finalAttrs.version}/glide-${finalAttrs.version}.module" "$out/glide-${finalAttrs.version}.module"
    install -Dm644 "$repoBase/glide/${finalAttrs.version}/glide-${finalAttrs.version}.pom" "$out/glide-${finalAttrs.version}.pom"
    install -Dm644 "$repoBase/gifdecoder/${finalAttrs.version}/gifdecoder-${finalAttrs.version}.aar" "$out/gifdecoder-${finalAttrs.version}.aar"
    install -Dm644 "$repoBase/gifdecoder/${finalAttrs.version}/gifdecoder-${finalAttrs.version}.module" "$out/gifdecoder-${finalAttrs.version}.module"
    install -Dm644 "$repoBase/gifdecoder/${finalAttrs.version}/gifdecoder-${finalAttrs.version}.pom" "$out/gifdecoder-${finalAttrs.version}.pom"
    install -Dm644 "$repoBase/disklrucache/${finalAttrs.version}/disklrucache-${finalAttrs.version}.aar" "$out/disklrucache-${finalAttrs.version}.aar"
    install -Dm644 "$repoBase/disklrucache/${finalAttrs.version}/disklrucache-${finalAttrs.version}.module" "$out/disklrucache-${finalAttrs.version}.module"
    install -Dm644 "$repoBase/disklrucache/${finalAttrs.version}/disklrucache-${finalAttrs.version}.pom" "$out/disklrucache-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Glide 5 AAR artifacts built from source";
    homepage = "https://github.com/bumptech/glide";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
})
