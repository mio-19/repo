{
  buildMavenRepositoryFromLockFile,
  jdk17_headless,
  stdenv,
  maven,
  lib,
  writableTmpDirAsHomeHook,
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
  mvnJdk ? jdk17_headless,
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
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = if stdenv.isDarwin then "${mvnJdk}" else "${mvnJdk}/lib/openjdk";
    };

    buildPhase = ''
      runHook preBuild

      mvn --offline -ntp -Dmaven.repo.local=${mavenRepository} ${lib.escapeShellArgs mvnFlags}

      runHook postBuild
    '';

    meta = meta // {
      platforms = meta.platforms or lib.platforms.unix;
    };
  }
  // lib.optionalAttrs (sourceRoot != null) { inherit sourceRoot; }
)
