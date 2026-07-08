{ ant, fetchFromGitHub }:
ant.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.9.6";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "ant";
      tag = "rel/${finalAttrs.version}";
      hash = "sha256-Y7Nj+/BHIgYoTxIrDFd87hxwOjAbIwu8NENNsr/ovRI=";
    };
  }
)
