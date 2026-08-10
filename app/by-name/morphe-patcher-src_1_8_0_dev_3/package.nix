{ fetchFromGitHub, applyPatches }:
applyPatches {
  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patcher";
    rev = "v1.8.0-dev.3";
    hash = "sha256-8K1LG6nuvV/W/Tn/NURJsR8aagaueMSo3XwFoO4w3BY=";
  };
  postPatch = ''
    patch -d . -p0 < ${./morphe-patcher.patch}
    patch -d . -p0 < ${./morphe-patcher-settings.patch}
    patch -d . -p0 < ${./morphe-patcher-version-name-suffix.patch}
  '';
}
