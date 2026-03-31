{ fetchFromGitHub, applyPatches }:
applyPatches {
  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patcher";
    rev = "v1.3.3";
    hash = "sha256-ehKW9/jlhhz2eGYEnioB6etq1gvH7eNroLw+yW8h3l0=";
  };
  patches = [
    ./morphe-patcher.patch
    ./morphe-patcher-settings.patch
  ];
}
