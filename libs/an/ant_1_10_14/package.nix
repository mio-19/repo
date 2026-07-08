{ ant, fetchFromGitHub }:
ant.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.10.14";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "ant";
      tag = "rel/${finalAttrs.version}";
      hash = "sha256-nt81VDsC+jFEgxQZ8acsDW17TozZiAIXL2u+4g+EpMw=";
    };
  }
)
