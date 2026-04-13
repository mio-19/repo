{ gradle_9_4_1, gradle2nixBuilders }:
gradle2nixBuilders.buildGradlePackage rec {
  pname = "gradle-wrapper";
  inherit (gradle_9_4_1.unwrapped)
    version
    src
    lockFile
    gradle
    overrides
    buildJdk
    nativeBuildInputs
    ;
}
