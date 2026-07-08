{ gson_2_13_0, fetchFromGitHub }:

gson_2_13_0.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.13.2";

    src = fetchFromGitHub {
      owner = "google";
      repo = "gson";
      tag = "gson-parent-${finalAttrs.version}";
      hash = "sha256-5XPl2SM7NaBhAuhSgIzWN5ACq5CWndimv0/l0EHc87c=";
    };

  }
)
