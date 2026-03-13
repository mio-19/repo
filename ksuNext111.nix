{ fetchgit }:
fetchgit {
  url = "https://github.com/KernelSU-Next/KernelSU-Next.git";
  rev = "v1.1.1";
  hash = "sha256-v8LuihrVauSAxWf7V+xgftSmFjJKTX9cUsoTWg7OTm4=";
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

    substituteInPlace "$out/kernel/Makefile" \
      --replace-fail \
      "-DKSU_VERSION=11998" \
      "-DKSU_VERSION=$KSU_VERSION"

    find "$out" -name .git -print0 | xargs -0 rm -rf
  '';
}
