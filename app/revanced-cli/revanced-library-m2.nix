{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  jdk17,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  revanced-jadb-m2,
  revanced-patcher-m2,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "9.3.1";
      hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
      defaultJava = jdk17;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "revanced-library-m2";
  version = "4.0.1";

  src = fetchFromGitHub {
    owner = "ReVanced";
    repo = "revanced-library";
    rev = "v${finalAttrs.version}";
    hash = "sha256-LQIbIXB0PviRfyLL2+bd/vxWW7rDBvHY0zT3y8QiJfA=";
  };

  gradleBuildTask = "publish";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "revanced-library";
    pkg = finalAttrs.finalPackage;
    data = ./revanced-library_deps.json;
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
        mkdir -p "$sourceRoot/.m2/repository"
        cp -a ${revanced-jadb-m2}/* "$sourceRoot/.m2/repository/"
        chmod -R u+w "$sourceRoot/.m2/repository"
        cp -a ${revanced-patcher-m2}/* "$sourceRoot/.m2/repository/"
        chmod -R u+w "$sourceRoot/.m2/repository"

        substituteInPlace "$sourceRoot/settings.gradle.kts" \
          --replace-fail '        maven {
                name = "githubPackages"
                url = uri("https://maven.pkg.github.com/revanced/revanced-library")
                credentials(PasswordCredentials::class)
            }' '        maven { url = uri("file://" + rootProject.projectDir.resolve(".m2/repository").absolutePath) }'

        substituteInPlace "$sourceRoot/library/build.gradle.kts" \
          --replace-fail '            maven {
                    name = "githubPackages"
                    url = uri("https://maven.pkg.github.com/revanced/revanced-library")
                    credentials(PasswordCredentials::class)
                }' '            maven { url = uri("file://" + rootProject.projectDir.resolve("build/m2").absolutePath) }'

        substituteInPlace "$sourceRoot/library/build.gradle.kts" \
          --replace-fail '    signAllPublications()
        extensions.getByType<SigningExtension>().useGpgCmd()
    ' ""
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
    mkdir -p "$out"
    cp -a build/m2/. "$out/"
    cp -a .m2/repository/. "$out/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "ReVanced library artifacts published to a local Maven repository";
    homepage = "https://github.com/ReVanced/revanced-library";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
