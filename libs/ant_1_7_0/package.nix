{
  ant,
  fetchFromGitHub,
}:
ant.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.7.0";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "ant";
      tag = "ANT_170";
      hash = "sha256-ogmusUIWXPMakblTP3FuvN7R4BLn06ha0BKPuGi6Py4=";
    };
  }
)
