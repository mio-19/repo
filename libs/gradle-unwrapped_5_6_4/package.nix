{
  gradle_5_1_1,
  jdk11_headless,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
}:
let
  gradle = gradle_5_1_1;
in
# https://github.com/NixOS/nixpkgs/blob/4ed2dff2b5c2970997ed3a12aae50181a352f719/doc/languages-frameworks/gradle.section.md
stdenv.mkDerivation (finalAttrs: {
  pname = "gradle-unwrapped";
  version = "5.6.4";
  src = fetchFromGitHub {
    owner = "gradle";
    repo = "gradle";
    rev = "v${finalAttrs.version}";
    hash = "sha256-sGLAyKn2PVIp4OBe1rvhU7Tact4cHvF9iaIlSZ4bGYE=";
  };

  nativeBuildInputs = [
    gradle
    makeWrapper
  ];
  # $(nix build .#gradle-unwrapped_5_6_4.mitmCache.updateScript --no-link --print-out-paths)
  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
    silent = false;
    useBwrap = false;
  };
  # this is required for using mitm-cache on Darwin
  __darwinAllowLocalNetworking = true;
  gradleFlags = [ "-Dfile.encoding=utf-8" ];
  installPhase = ''
    mkdir -p $out
    cp -r  build/libs/ $out/
  '';
})
