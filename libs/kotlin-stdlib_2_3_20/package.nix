{
  gradle_8_14,
  jdk11_headless,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  writableTmpDirAsHomeHook,
}:
# https://github.com/NixOS/nixpkgs/blob/4ed2dff2b5c2970997ed3a12aae50181a352f719/doc/languages-frameworks/gradle.section.md
stdenv.mkDerivation (
  finalAttrs:
  let
    inherit (finalAttrs) gradle;
  in
  {
    # https://github.com/JetBrains/kotlin/blob/v2.3.20/gradle/wrapper/gradle-wrapper.properties
    gradle = gradle_8_14;
    pname = "kotlin-stdlib";
    version = "2.3.20";

    jdk = jdk11_headless;

    src = fetchFromGitHub {
      owner = "JetBrains";
      repo = "kotlin";
      rev = "v${finalAttrs.version}";
      hash = "sha256-rl0GETzs+nXwMMJLT1g8lrC+I5mCuR0eXvb8XkmPTyg=";
    };
    postPatch = ''
      rm -fr gradle/verification-metadata.xml gradle/wrapper
    '';
    sourceRoot = "${finalAttrs.src.name}/libraries/stdlib";

    nativeBuildInputs = [
      writableTmpDirAsHomeHook
      gradle
      makeWrapper
      finalAttrs.jdk
    ];
    # $(nix build .#kotlin-stdlib_2_3_20.mitmCache.updateScript --no-link --print-out-paths)
    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./deps.json;
      silent = false;
      useBwrap = false;
    };
    env.JAVA_HOME = finalAttrs.jdk.passthru.home;
    # this is required for using mitm-cache on Darwin
    __darwinAllowLocalNetworking = true;
    gradleFlags = [
      "--no-configuration-cache"
      "-Dfile.encoding=utf-8"
      "-Dorg.gradle.java.home=${finalAttrs.jdk.passthru.home}"
    ];
    preBuild = ''
      chmod -R a+w ../..
      chmod -R a+w ../../.. || true
      export GRADLE_USER_HOME="$HOME/.gradle"
      gradleFlagsArray+=("-Dgradle.user.home=$GRADLE_USER_HOME"  --gradle-user-home "$GRADLE_USER_HOME") 
    '';
    # https://github.com/NixOS/nixpkgs/pull/383115/changes
    gradleUpdateScript = ''
      runHook preBuild
      export GRADLE_OPTS='${builtins.concatStringsSep " " finalAttrs.gradleFlags}'
      gradle ${builtins.concatStringsSep " " finalAttrs.gradleFlags} --write-verification-metadata sha256
    '';
    # github.com/JetBrains/kotlin/tree/v2.3.20/libraries/stdlib
    buildPhase = ''
      runHook preBuild
      gradle :tools:kotlin-stdlib-gen:run
      runHook postBuild
    '';
    installPhase = ''
      mkdir -p $out
      cp -r  build/libs/ $out/
    '';
  }
)
# cd libraries/stdlib
# nix-shell -p jdk17
# nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.14
