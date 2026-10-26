{ fetchgit }:
fetchgit {
  url = "https://github.com/tiann/KernelSU.git";
  rev = "v1.0.5";
  hash = "sha256-XrfyLfl1BVN0p+Xy3DD7JGLVpgDqkrL+MRJLz36q17Y=";
  leaveDotGit = true;
  deepClone = true;
  # populate values that require us to use git and deepClone. By doing this in postFetch we
  # can delete .git afterwards and maintain better reproducibility of the src.
  postFetch = ''
    cd "$out"

    KSU_GIT_VERSION="$(git rev-list --count HEAD)"
    KSU_VERSION="$((10000 + KSU_GIT_VERSION + 200))"

    echo "KSU_VERSION=$KSU_VERSION"

    substituteInPlace "$out/kernel/Makefile" \
      --replace-fail \
      "ccflags-y += -DKSU_VERSION=16" \
      "ccflags-y += -DKSU_VERSION=$KSU_VERSION"

    find "$out" -name .git -print0 | xargs -0 rm -rf
  '';
}
