{ gson_2_2_4, fetchFromGitHub }:
gson_2_2_4.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.10.1";
    src = fetchFromGitHub {
      owner = "google";
      repo = "gson";
      tag = "gson-parent-${finalAttrs.version}";
      hash = "sha256-Hjex840nPoJ99l41VeMa9Eiq81QZOEYB2MGvdzQwMus=";
    };
  }
)
