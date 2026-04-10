{
  ant_fromsrc,
  fetchFromGitHub,
  jdk8_headless,
  lib,
  stdenv,
}:

let
  postfix = if stdenv.isDarwin then "" else "/lib/openjdk";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "ant";
  version = "1.9.3";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "ant";
    tag = "rel/${finalAttrs.version}";
    hash = "sha256-Dalkg10BUNKKoSISJQ3b7trUv+yD26pNs3kTY9N2dxo=";
  };

  nativeBuildInputs = [
    ant_fromsrc
    jdk8_headless
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8_headless}${postfix}
    export CLASSPATH=${jdk8_headless}${postfix}/lib/tools.jar
    ant -noinput -Dbuild.compiler=modern jars

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    install -Dm644 build/lib/ant.jar "$out/ant-${finalAttrs.version}.jar"
    install -Dm644 build/lib/ant-launcher.jar "$out/ant-launcher-${finalAttrs.version}.jar"

    for artifactId in ant ant-launcher ant-parent; do
      cat > "$out/$artifactId-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>org.apache.ant</groupId>
      <artifactId>$artifactId</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java-based build tool";
    homepage = "https://ant.apache.org/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
