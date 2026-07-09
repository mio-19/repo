{ ant, fetchFromGitHub }:
ant.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.10.13";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "ant";
      tag = "rel/${finalAttrs.version}";
      hash = "sha256-JfHBjupJGalFmpvapbt7lVsXecBl2HZ4+4eKq+20jkg=";
    };
  }
)
