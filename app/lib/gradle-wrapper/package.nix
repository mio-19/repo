{ gradle_9_4_1, gradle2nixBuilders }:
let
  gradle = gradle_9_4_1;
in
gradle2nixBuilders.buildGradlePackage rec {
  pname = "gradle-wrapper";
  inherit (gradle.unwrapped)
    version
    src
    lockFile
    gradle
    overrides
    buildJdk
    nativeBuildInputs
    ;
}
