{
  fetchFromGitHub,
  jdk17_headless,
  lib,
  stdenv,
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

  nativeBuildInputs = [ jdk17_headless ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk17_headless}/lib/openjdk
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

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
