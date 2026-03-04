{ fetchgit }:
fetchgit {
  url = "https://github.com/tiann/KernelSU.git";
  rev = "v3.1.0";
  hash = "sha256-R1EROyD/3tgg4tI3Q3DKMBiMLKccpXQOf4yHibL1Yz4=";
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
      "ccflags-y += -DKSU_VERSION=16" \
      "ccflags-y += -DKSU_VERSION=$KSU_VERSION"

    find "$out" -name .git -print0 | xargs -0 rm -rf
  '';
}
