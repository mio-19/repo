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
}:
stdenv.mkDerivation (finalAttrs:
let koreader_src = fetchFromGitHub {
      name = "koreader";
    owner = "koreader";
    repo = "koreader";
    tag = "v${finalAttrs.version}";
    leaveDotGit = true;
    hash = "";
    fetchSubmodules = true;
    }; in{
  pname = "koreader";
  version = "2026.03";

  srcs = [
    (koreader_src)
  ];

})