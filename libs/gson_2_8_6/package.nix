{ gson_2_2_4, fetchFromGitHub }:
gson_2_2_4.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.8.6";
    src = fetchFromGitHub {
      owner = "google";
      repo = "gson";
      tag = "gson-parent-${finalAttrs.version}";
      hash = "sha256-Y96Xx01C7t2vrM/WUgiu9tG5Lst2fhrgBatBFve4ZU4=";
    };
  }
)
