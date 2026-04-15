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
  applyPatches,
}:
stdenv.mkDerivation (
  finalAttrs:
  # git clone --recurse-submodules  https://github.com/koreader/koreader.git
  # git checkout v2026.03
  let
    repos = import ./repos.nix { inherit fetchgit; };
    repos-replace = repo: ''--replace-quiet "${repo.url}" "${repo}" '';
  in
  {
    pname = "koreader";
    version = "2026.03";
    src = fetchFromGitHub {
      name = "koreader";
      owner = "koreader";
      repo = "koreader";
      tag = "v${finalAttrs.version}";
      leaveDotGit = true;
      hash = "sha256-Ww2DBPkr7Q5Is+HHrmjt9WfIordHRGdMuunFfB+G2hg=";
      fetchSubmodules = true;
    };
    sourceRoot = "${finalAttrs.src.name}";
    postPatch = ''
      substituteInPlace $(find . -name CMakeLists.txt) ${lib.concatMapStrings repos-replace repos}
    '';

    passthru.srcOnly = srcOnly finalAttrs.finalPackage;
  }
)
