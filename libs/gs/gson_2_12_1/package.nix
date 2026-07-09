{
  gson_2_13_0,
  fetchFromGitHub,
}:
gson_2_13_0.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.12.1";
    src = fetchFromGitHub {
      owner = "google";
      repo = "gson";
      tag = "gson-parent-${finalAttrs.version}";
      hash = "sha256-4AQLPAy4yrQXGe3dkGGtAGrbMFCLUEJT/RDJGq4gaFA=";
    };
  }
)
