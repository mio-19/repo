{ fetchFromGitHub, applyPatches }:
applyPatches {
  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patcher";
    tag = "v2.3.0";
    hash = "sha256-vNNFFYpsdY/G4TL4xYEGFqJLTsa38BiGazdSCqNMfFg=";
  };
  postPatch = ''
    patch -d . -p0 < ${./morphe-patcher.patch}
    patch -d . -p0 < ${./morphe-patcher-version-name-suffix.patch}
  '';
}
