pkgs@{
  buildMavenRepositoryFromLockFile,
  jdk17_headless,
  stdenv,
  maven,
  lib,
  writableTmpDirAsHomeHook,
}:
lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;

  excludeDrvArgNames = [
    "lockFile"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      name ? "${args.pname}-${args.version}",

      src ? null,
      srcs ? null,
      preUnpack ? null,
      unpackPhase ? null,
      postUnpack ? null,
      cargoPatches ? [ ],
      patches ? [ ],
      sourceRoot ? null,
      cargoRoot ? null,
      logLevel ? "",
      buildInputs ? [ ],
      nativeBuildInputs ? [ ],
      mvnJdk ? jdk17_headless,
      mvnFlags ? [ "package" ],
      maven ? pkgs.maven,
      lockFile ? null,
      mavenRepository ? buildMavenRepositoryFromLockFile { file = lockFile; },
      ...
    }@args:
    {

      env = {
        JAVA_HOME = mvnJdk.passthru.home;
      }
      // args.env or { };

      nativeBuildInputs = nativeBuildInputs ++ [
        maven
        mvnJdk
        writableTmpDirAsHomeHook
      ];
      buildPhase =
        args.buildPhase or ''
          runHook preBuild

          mvn --offline -ntp -Dmaven.repo.local=${mavenRepository} ${lib.escapeShellArgs mvnFlags}

          runHook postBuild
        '';

      meta = {
        platforms = lib.platforms.unix;
      }
      // args.meta or { };
    };
}
