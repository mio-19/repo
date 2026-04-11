{
  fetchFromGitHub,
  jdk25_headless,
  lib,
  stdenv,
  writableTmpDirAsHomeHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ant";
  version = "1.10.15";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "ant";
    tag = "rel/${finalAttrs.version}";
    hash = "sha256-lRaDj8MMfuMqjXwHglZlKgqUmkbbs0dCTDFF61zW5Qg=";
  };

  nativeBuildInputs = [
    jdk25_headless
    writableTmpDirAsHomeHook
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    sh ./bootstrap.sh jars

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share"
    cp -r bootstrap "$out/share/ant"
    ln -s "$out/share/ant/bin/ant" "$out/bin/ant"
    ln -s "$out/share/ant/bin/antRun" "$out/bin/antRun"

    runHook postInstall
  '';

  passthru.home = "${finalAttrs.finalPackage}/share/ant";

  meta = with lib; {
    description = "Java-based build tool built from source";
    homepage = "https://ant.apache.org/";
    license = licenses.asl20;
    mainProgram = "ant";
    platforms = platforms.unix;
  };
})
