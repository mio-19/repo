# Builds morphe-library and publishes to a local maven repo layout.
# This is needed because morphe-library is Kotlin Multiplatform and its
# -jvm variant can't be cleanly substituted via Gradle composite builds.
{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-35
    s.build-tools-34-0-0
    s.build-tools-35-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.14.3";
      hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
      defaultJava = jdk21;
    }).wrapped;

  jadb-src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "jadb";
    rev = "1b9f076bda455b00fa20c73137a3ed076e65f7f6";
    hash = "sha256-VGAd8O7q5xMThFAmMPp4TLqamFtThZY2oKFyofo57Ng=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "morphe-library-m2";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-library";
    rev = "v${finalAttrs.version}";
    hash = "sha256-1RCxI7pBt2bZ/AiZ3EyS6JYRZlW7bhb88pfEc6ViaiA=";
  };

  gradleBuildTask = "publish";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "morphe-library";
    pkg = finalAttrs.finalPackage;
    data = ./morphe-library_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
  };

  postUnpack = ''
    root="$PWD"

    # Build jadb (zero runtime deps) into local maven repo.
    cp -a ${jadb-src} "$root/jadb"
    chmod -R u+w "$root/jadb"
    mkdir -p "$root/.m2/repository/app/morphe/jadb/1.2.1"
    (
      cd "$root/jadb"
      find src -name '*.java' > /tmp/jadb-sources.txt
      mkdir -p build/classes
      ${jdk21}/bin/javac -source 1.8 -target 1.8 \
        -d build/classes \
        @/tmp/jadb-sources.txt 2>/dev/null || true
      cd build/classes
      ${jdk21}/bin/jar cf "$root/.m2/repository/app/morphe/jadb/1.2.1/jadb-1.2.1.jar" .
    )
    cat > "$root/.m2/repository/app/morphe/jadb/1.2.1/jadb-1.2.1.pom" << 'POMEOF'
    <?xml version="1.0" encoding="UTF-8"?>
    <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
      <modelVersion>4.0.0</modelVersion>
      <groupId>app.morphe</groupId>
      <artifactId>jadb</artifactId>
      <version>1.2.1</version>
    </project>
    POMEOF

    # Patch out GitHub Packages from morphe-library.
    substituteInPlace "$sourceRoot/build.gradle.kts" \
      --replace-fail '    maven {
        // A repository must be specified for some reason. "registry" is a dummy.
        url = uri("https://maven.pkg.github.com/MorpheApp/registry")
        credentials {
            username = project.findProperty("gpr.user") as String? ?: System.getenv("GITHUB_ACTOR")
            password = project.findProperty("gpr.key") as String? ?: System.getenv("GITHUB_TOKEN")
        }
    }' '    maven { url = uri("file://'"$root"'/.m2/repository") }'

    # Disable signing.
    echo 'tasks.withType<Sign> { enabled = false }' >> "$sourceRoot/build.gradle.kts"

    # Remove GitHub Packages from publishing and add a local one for 'publish' task
    substituteInPlace "$sourceRoot/build.gradle.kts" \
      --replace-fail '        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/MorpheApp/morphe-library")
            credentials {
                username = project.findProperty("gpr.user") as String? ?: System.getenv("GITHUB_ACTOR")
                password = project.findProperty("gpr.key") as String? ?: System.getenv("GITHUB_TOKEN")
            }
        }' '        maven { url = uri("file://" + rootProject.projectDir.resolve("build/m2").absolutePath) }'
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
    # Copy artifacts from the local maven repo and jadb
    # Jadb is in ../.m2/repository
    # Library artifacts are in build/m2
    if [ -d "build/m2" ]; then
      cp -a build/m2/. "$out/"
    fi
    if [ -d "../.m2/repository" ]; then
      cp -a ../.m2/repository/. "$out/"
    fi
    runHook postInstall
  '';

  meta = with lib; {
    description = "Morphe Library pre-built to local maven repo";
    homepage = "https://github.com/MorpheApp/morphe-library";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
