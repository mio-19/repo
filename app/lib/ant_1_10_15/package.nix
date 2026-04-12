{ ant, fetchFromGitHub }:
ant.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.10.15";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "ant";
      tag = "rel/${finalAttrs.version}";
      hash = "sha256-lRaDj8MMfuMqjXwHglZlKgqUmkbbs0dCTDFF61zW5Qg=";
    };
  }
)
