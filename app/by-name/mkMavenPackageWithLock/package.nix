{
  buildMavenRepositoryFromLockFile,
  jdk17,
  stdenv,
  maven,
  lib,
}:
{
  pname,
  version,
  src,
  lockFile,
  installPhase,
  meta,
  patches ? [ ],
  sourceRoot ? null,
  mvnJdk ? jdk17,
  mvnFlags ? [ "package" ],
}:
let
  mavenRepository = buildMavenRepositoryFromLockFile { file = lockFile; };
in
stdenv.mkDerivation (
  {
    inherit
      pname
      version
      src
      patches
      installPhase
      ;

    nativeBuildInputs = [
      maven
      mvnJdk
    ];

    env = {
      JAVA_HOME = if stdenv.isDarwin then "${mvnJdk}" else "${mvnJdk}/lib/openjdk";
    };

    buildPhase = ''
      runHook preBuild

      export HOME="$NIX_BUILD_TOP/home"
      mkdir -p "$HOME"

      mvn --offline -ntp -Dmaven.repo.local=${mavenRepository} ${lib.escapeShellArgs mvnFlags}

      runHook postBuild
    '';

    meta = meta // {
      platforms = meta.platforms or lib.platforms.unix;
    };
  }
  // lib.optionalAttrs (sourceRoot != null) { inherit sourceRoot; }
)
