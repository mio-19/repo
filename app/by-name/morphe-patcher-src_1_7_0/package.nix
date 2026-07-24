{ fetchFromGitHub, applyPatches }:
applyPatches {
  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patcher";
    tag = "v1.7.0";
    hash = "sha256-8hhTDPSvmlAa/gxIGlue89MmKYFYu/+b6DHEH6Nhfio=";
  };
  postPatch = ''
    patch -d . -p0 < ${./morphe-patcher.patch}
    patch -d . -p0 < ${./morphe-patcher-settings.patch}
    patch -d . -p0 < ${./morphe-patcher-version-name-suffix.patch}
  '';
}
