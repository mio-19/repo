{ gson_2_2_4, fetchFromGitHub }:
gson_2_2_4.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.8.9";
    src = fetchFromGitHub {
      owner = "google";
      repo = "gson";
      tag = "gson-parent-${finalAttrs.version}";
      hash = "sha256-jKVpO5NHGitR+MACqg20ul3Kx5eVn0iiopGJYL/dIdo=";
    };
  }
)
