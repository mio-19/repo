{fetchFromGitHub,stdenv}:

stdenv.mkDerivation (finalAttrs: {
pname = "groovy";
version = "1.8.9";
src = fetchFromGitHub {
  owner = "apache";
  repo = "groovy";
  rev = "GROOVY_1_8_9";
  hash="sha256-pG9jsyMEUMVoeqnI04Tk5g0Y5VRxBcTxVSw4HyGqF0E=";
};
})