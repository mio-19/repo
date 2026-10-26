{
  fetchgit,
  applyPatches,
  fetchpatch,
}:
applyPatches {
  name = "KernelSU-Next";
  src = fetchgit {
    url = "https://github.com/KernelSU-Next/KernelSU-Next.git";
    rev = "v3.1.0";
    hash = "sha256-YAuUnrNRQSpNAmWtSa7aVB5gm+LW6BSdw91C4hITFNY=";
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
        "KSU_VERSION_FALLBACK := 1" \
        "KSU_VERSION_FALLBACK := $KSU_VERSION" \
        --replace-fail \
        "KSU_VERSION_TAG_FALLBACK := v0.0.1" \
        "KSU_VERSION_TAG_FALLBACK := $KSU_VERSION_TAG"

      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };
  patches = [
    (fetchpatch {
      name = "kernel: fix process marking for built-in mode (tiann/KernelSU#3284)";
      url = "https://github.com/KernelSU-Next/KernelSU-Next/commit/ca8295ad20be56241575630506e0597b911d2441.patch";
      hash = "sha256-V5FuBwFXY/4kq9ZOoqzwnOR1hfi5KVOq9pk1wU7viO0=";
    })
  ];
}
