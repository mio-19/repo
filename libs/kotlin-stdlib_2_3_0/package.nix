{
  kotlin-stdlib_2_3_20,
  fetchFromGitHub,
  lib,
  libsUtils,
  jdk17_headless,
}:
kotlin-stdlib_2_3_20.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.3.0";
    jdk = jdk17_headless;
    src = fetchFromGitHub {
      owner = "JetBrains";
      repo = "kotlin";
      rev = "v${finalAttrs.version}";
      hash = "sha256-n3tMrvS6grDPWDBq9VwclWKwAOqw8JmGmtE3R1dhsZ4=";
    };
    # $(nix build .#kotlin-stdlib_2_3_0.mitmCache.updateScript --no-link --print-out-paths)
    mitmCache = finalAttrs.gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./deps.json;
      silent = false;
      useBwrap = false;
    };

    gradleFlags = (prevAttrs.gradleFlags or [ ]) ++ [
      "--max-workers=1"
      "-Dorg.gradle.jvmargs=-Xmx2g"
    ];
  }
)
