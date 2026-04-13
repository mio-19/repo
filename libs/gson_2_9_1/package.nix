{ gson_2_2_4, fetchFromGitHub }:
gson_2_2_4.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.9.1";
    src = fetchFromGitHub {
      owner = "google";
      repo = "gson";
      tag = "gson-parent-${finalAttrs.version}";
      hash = "sha256-glTd/quExpzigpzIqbwbrl5Rgvsf+K/c21REnMcsTXo=";
    };
  }
)
