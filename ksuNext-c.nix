{ fetchgit }:
fetchgit {
  url = "https://github.com/KernelSU-Next/KernelSU-Next.git";
  rev = "690042684b17064f228278d35f51b54f5b6d0224";
  hash = "sha256-LKtVO2CJ5h6tNJpSxlh2BNpuTEG5j5Gk5NEVQ4AyOEQ=";
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
}
