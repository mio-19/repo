{ gson_2_13_0, fetchFromGitHub }:
gson_2_13_0.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.13.1";
    src = fetchFromGitHub {
      owner = "google";
      repo = "gson";
      tag = "gson-parent-${finalAttrs.version}";
      hash = "sha256-D+CjEE5ZCIJ1+93lGPlg7vlZdbpiscNBb+Q0hZG0Nwg=";
    };
  }
)
