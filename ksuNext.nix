{ fetchgit }:
fetchgit rec {
  url = "https://github.com/KernelSU-Next/KernelSU-Next.git";
  rev = "v3.1.0";
  hash = "sha256-YAuUnrNRQSpNAmWtSa7aVB5gm+LW6BSdw91C4hITFNY=";
  leaveDotGit = true;
  deepClone = true;
  # populate values that require us to use git and deepClone. By doing this in postFetch we
  # can delete .git afterwards and maintain better reproducibility of the src.
  postFetch = ''
    cd "$out"

    git rev-parse HEAD > "$out/COMMIT"
    date -u -d "@$(git log -1 --pretty=%ct)" "+%Y-%m-%dT%H:%M:%SZ" > "$out/SOURCE_DATE_EPOCH"

    KSU_GIT_VERSION="$(git rev-list --count HEAD)"
    KSU_VERSION="$((10000 + KSU_GIT_VERSION + 200))"
    echo "$KSU_VERSION" > "$out/KSU_VERSION"

    echo "KSU_VERSION=$KSU_VERSION"

    substituteInPlace "$out/kernel/Kbuild" \
      --replace-fail \
      "KSU_VERSION_FALLBACK := 1" \
      "KSU_VERSION_FALLBACK := $KSU_VERSION" \
      --replace-fail \
      "KSU_VERSION_TAG_FALLBACK := v0.0.1" \
      "KSU_VERSION_TAG_FALLBACK := ${rev}"

    find "$out" -name .git -print0 | xargs -0 rm -rf
  '';
}
