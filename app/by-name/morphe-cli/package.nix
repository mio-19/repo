{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  writableTmpDirAsHomeHook,
  git,
  androidSdkBuilder,
  morphe-library-m2,
  apktool-src,
  multidexlib2-src,
  morphe-patcher-src,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-33
    s.platforms-android-34
    s.platforms-android-35
    s.build-tools-35-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.14.3";
      hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
      defaultJava = jdk21;
    }).wrapped;

  arsclib-src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "ARSCLib";
    rev = "d003b5ff1ca91fb8c5105619cf1108b450387061";
    hash = "sha256-2UO6zDAFeURrt9U9f7gNDA8J5X3o8Ct96/rItUq644g=";
  };

in
stdenv.mkDerivation (finalAttrs: {
  pname = "morphe-cli";
  version = "1.6.3";

  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-cli";
    rev = "v${finalAttrs.version}";
    hash = "sha256-tUQoJORLzvVdHIoj8dJFOgTGFfo77S1VexGrkydxXsg=";
  };

  gradleBuildTask = "shadowJar";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./morphe-cli_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    makeWrapper
    writableTmpDirAsHomeHook
    git
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
  };

  # Set up the workspace: arrange all dependency sources as sibling directories,
  # patch out all GitHub Packages repositories, and configure composite builds.
  postUnpack = ''
    root="$PWD"

    # Copy dependency sources as writable sibling directories.
    cp -a ${morphe-patcher-src} "$root/morphe-patcher"
    chmod -R u+w "$root/morphe-patcher"

    cp -a ${arsclib-src} "$root/ARSCLib"
    chmod -R u+w "$root/ARSCLib"

    cp -a ${apktool-src} "$root/Apktool"
    chmod -R u+w "$root/Apktool"

    cp -a ${multidexlib2-src} "$root/multidexlib2"
    chmod -R u+w "$root/multidexlib2"

    # Set up local maven repo with pre-built morphe-library (from separate derivation).
    mkdir -p "$root/.m2/repository"
    cp -a ${morphe-library-m2}/* "$root/.m2/repository/"

    # ---- Patch GitHub Packages repos out of build.gradle files ----

    # morphe-cli: replace GitHub Packages with local maven repo
    gh_credentials=$'        credentials {\n            username = project.findProperty("gpr.user") as String? ?: System.getenv("GITHUB_ACTOR")\n            password = project.findProperty("gpr.key") as String? ?: System.getenv("GITHUB_TOKEN")\n        }'

    substituteInPlace "$sourceRoot/build.gradle.kts" \
      --replace-fail '        url = uri("https://maven.pkg.github.com/MorpheApp/registry")' \
                     '        url = uri("file://" + rootProject.projectDir.resolve("../.m2/repository").absolutePath)'
    substituteInPlace "$sourceRoot/build.gradle.kts" --replace-fail "$gh_credentials" ""

    # ---- Remove morphe-library from composite builds (use pre-built m2 instead) ----
    # morphe-cli settings tries to include morphe-library as composite but KMP
    # JVM variant can't be substituted that way. Remove it.
    substituteInPlace "$sourceRoot/settings.gradle.kts" \
      --replace-fail '"morphe-library" to "app.morphe:morphe-library",' ""

    # The foojay resolver plugin is only used for toolchain discovery.
    # Nix already pins Java, so remove this plugin to avoid an extra plugin fetch.
    substituteInPlace "$sourceRoot/settings.gradle.kts" \
      --replace-fail '    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"' ""

    # Use the pinned Nix JDK instead of Gradle-managed Java toolchains.
    substituteInPlace "$sourceRoot/build.gradle.kts" \
      --replace-fail '        languageVersion.set(JavaLanguageVersion.of(17))' \
                     '        languageVersion.set(JavaLanguageVersion.of(21))'
    substituteInPlace "$sourceRoot/build.gradle.kts" \
      --replace-fail '        vendor.set(JvmVendorSpec.ADOPTIUM)' ""
    substituteInPlace "$sourceRoot/build.gradle.kts" \
      --replace-fail '        jvmTarget.set(JvmTarget.JVM_17)' \
                     '        jvmTarget.set(JvmTarget.JVM_21)'

    # ---- Disable signing tasks (no GPG in sandbox) ----
    echo 'tasks.withType<Sign> { enabled = false }' >> "$sourceRoot/build.gradle.kts"
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall

    jar_path="$(find build/libs -name '*-all.jar' | head -n 1)"
    test -n "$jar_path" && test -f "$jar_path"
    install -Dm644 "$jar_path" "$out/share/morphe-cli/morphe-cli.jar"

    makeWrapper ${jdk21}/bin/java $out/bin/morphe-cli \
      --add-flags "-jar $out/share/morphe-cli/morphe-cli.jar"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Console / terminal patching tool for Android apps (built from source)";
    homepage = "https://github.com/MorpheApp/morphe-cli";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
    mainProgram = "morphe-cli";
  };
})
