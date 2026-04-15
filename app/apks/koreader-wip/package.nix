{
  mk-apk-package,
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  fetchgit,
  androidSdkBuilder,
  gradle_8_14_3,
  jdk17_headless,
  git,
  cmake,
  ninja,
  pkg-config,
  autoconf,
  automake,
  libtool,
  gettext,
  m4,
  which,
  python3,

  writableTmpDirAsHomeHook,
  unzip,
  util-linux,
  meson,
  curl,
  buildPackages,
  bash,
  buildFHSEnv,
  srcOnly,
}:
stdenv.mkDerivation (
  finalAttrs:
  # git clone --recurse-submodules  https://github.com/koreader/koreader.git
  # git checkout v2026.03
  let
    koreader_src = fetchFromGitHub {
      name = "koreader";
      owner = "koreader";
      repo = "koreader";
      tag = "v${finalAttrs.version}";
      leaveDotGit = true;
      hash = "";
      fetchSubmodules = true;
    };
    repos = import ./repos.nix { inherit fetchgit; };
  in
  {
    pname = "koreader";
    version = "2026.03";

    srcs = [
      koreader_src
    ]
    ++ repos;
    passthru.srcOnly = srcOnly finalAttrs.finalPackage;
  }
)
