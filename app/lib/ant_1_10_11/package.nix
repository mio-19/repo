{ ant, fetchFromGitHub }:
ant.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.10.11";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "ant";
      tag = "rel/${finalAttrs.version}";
      hash = "sha256-nHIZPl35lnaS5U6AL8qX7dmuN+T03QpHTXWGjYROUmw=";
    };
  }
)
