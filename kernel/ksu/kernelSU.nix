{ fetchgit }:
fetchgit {
  url = "https://github.com/tiann/KernelSU.git";
  rev = "v3.2.1";
  hash = "sha256-3jj+OLZFthm97b8IysRQ1PgWCs6yeWuA/Z0NAekW2bE=";
  leaveDotGit = true;
  deepClone = true;
  # populate values that require us to use git and deepClone. By doing this in postFetch we
  # can delete .git afterwards and maintain better reproducibility of the src.
  postFetch = ''
    cd "$out"

    KSU_GIT_VERSION="$(git rev-list --count HEAD)"
    KSU_VERSION="$((10000 + KSU_GIT_VERSION + 200))"
    KSU_VERSION_TAG="$(git describe --tags --abbrev=0)"

    echo "KSU_VERSION=$KSU_VERSION"

    substituteInPlace "$out/kernel/Kbuild" \
      --replace-fail \
      "ccflags-y += -DKSU_VERSION=16" \
      "ccflags-y += -DKSU_VERSION=$KSU_VERSION"

    find "$out" -name .git -print0 | xargs -0 rm -rf
  '';
}
