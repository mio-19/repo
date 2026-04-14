{
  gradle_8_14,
  jdk11_headless,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
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

    src = fetchFromGitHub {
      owner = "JetBrains";
      repo = "kotlin";
      rev = "v${finalAttrs.version}";
      hash = "";
    };

    nativeBuildInputs = [
      gradle
      makeWrapper
    ];
    # $(nix build .#kotlin-stdlib_2_3_20.mitmCache.updateScript --no-link --print-out-paths)
    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./deps.json;
    };
    # this is required for using mitm-cache on Darwin
    __darwinAllowLocalNetworking = true;
    gradleFlags = [ "-Dfile.encoding=utf-8" ];
    installPhase = ''
      mkdir -p $out
      cp -r  build/libs/ $out/
    '';
  }
)
