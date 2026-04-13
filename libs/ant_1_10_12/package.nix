{ ant, fetchFromGitHub }:
ant.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.10.12";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "ant";
      tag = "rel/${finalAttrs.version}";
      hash = "sha256-1VD23GWWvj2CFUcZMPZB6+e6MqMEE5DCVQ5Ts0ZbYb0=";
    };
  }
)
