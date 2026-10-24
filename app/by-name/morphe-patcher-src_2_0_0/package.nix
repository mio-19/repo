{ fetchFromGitHub, applyPatches }:
applyPatches {
  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patcher";
    tag = "v2.0.0";
    hash = "sha256-ZBQxQXW4VKcKwvciVJUMH+HPN4wUJjeIFMIDAp+V65g=";
  };
  postPatch = ''
    patch -d . -p0 < ${./morphe-patcher.patch}
    patch -d . -p0 < ${./morphe-patcher-settings.patch}
    patch -d . -p0 < ${./morphe-patcher-version-name-suffix.patch}
  '';
}
