{
  kotlin-stdlib_2_3_20,
  fetchFromGitHub,
}:
kotlin-stdlib_2_3_20.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.3.0";
    src = fetchFromGitHub {
      owner = "JetBrains";
      repo = "kotlin";
      rev = "v${finalAttrs.version}";
      hash = "";
    };
    # $(nix build .#kotlin-stdlib_2_3_20.mitmCache.updateScript --no-link --print-out-paths)
    mitmCache = finalAttrs.gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./deps.json;
      silent = false;
      useBwrap = false;
    };
  }
)
