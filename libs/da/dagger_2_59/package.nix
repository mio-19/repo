{
  dagger_common,
  jakarta_inject_api_2_0_1,
  javax_inject_1,
  jspecify_1_0_0,
}:

dagger_common {
  version = "2.59";
  srcHash = "sha256-B2bPSuzT/+YrIfR+htY02qdK/1ygWt6o3KogsOY99SE=";
  pomHash = "sha256-DkeEZhjHobeoEk/SBiOmZ2Q9c8vgpWG7hwVhUaqWdTg=";
  classpathJars = [
    "${javax_inject_1}/javax.inject-${javax_inject_1.version}.jar"
    "${jakarta_inject_api_2_0_1}/jakarta.inject-api-${jakarta_inject_api_2_0_1.version}.jar"
    "${jspecify_1_0_0}/jspecify-${jspecify_1_0_0.version}.jar"
  ];
}
