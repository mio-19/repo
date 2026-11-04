{ fetchFromGitHub, applyPatches }:
applyPatches {
  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patcher";
    tag = "v2.1.0";
    hash = "sha256-RCnW5Smw22bs3gGbj8nbw3hBECsHDUoeXiuVKDnoArY=";
  };
  postPatch = ''
    patch -d . -p0 < ${./morphe-patcher.patch}
    patch -d . -p0 < ${./morphe-patcher-version-name-suffix.patch}
  '';
}
