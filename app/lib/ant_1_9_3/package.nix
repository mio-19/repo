{ ant, fetchFromGitHub }:
ant.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.9.3";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "ant";
      tag = "rel/${finalAttrs.version}";
      hash = "sha256-Dalkg10BUNKKoSISJQ3b7trUv+yD26pNs3kTY9N2dxo=";
    };
  }
)
