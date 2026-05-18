{
  lib,
  stdenv,
  fetchurl,
  jikes,
  jamvm-1_5_1,
  unzip,
  zip,
}:
stdenv.mkDerivation rec {
  pname = "ant";
  version = "1.8.4";

  src = fetchurl {
    url = "https://archive.apache.org/dist/ant/source/apache-ant-${version}-src.tar.bz2";
    sha256 = "sha256-XeZfe6P2fkNv//zcCnP1kdEAbp+0GvhjLB8fhNSj4LE=";
  };

  nativeBuildInputs = [
    jikes
    jamvm-1_5_1
    unzip
    zip
  ];

  env = {
    JAVA_HOME = jamvm-1_5_1;
    JAVACMD = "${jamvm-1_5_1}/bin/jamvm";
    JAVAC = "${jikes}/bin/jikes";
    CLASSPATH = "${jamvm-1_5_1}/lib/rt.jar";
    ANT_OPTS = "-Dbuild.compiler=jikes";
    BOOTJAVAC_OPTS = "-nowarn";
    HOME = "/tmp";
  };

  patchPhase = ''
    substituteInPlace bootstrap.sh \
      --replace-fail '"''${JAVACMD}" ' '"''${JAVACMD}" -Xnocompact -Xnoinlining '
    substituteInPlace build.xml \
      --replace-fail 'depends="jars,test-jar"' 'depends="jars"'
  '';

  buildPhase = ''
    mkdir -p $out
    touch $HOME/.ant.properties
    bash -x bootstrap.sh -Ddist.dir=$out
  '';

  installPhase = "true";

  meta = with lib; {
    description = "Apache Ant, a Java-based build tool (bootstrap version)";
    homepage = "https://ant.apache.org/";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
