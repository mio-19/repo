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
    url = "mirror://apache/ant/source/apache-ant-${version}-src.tar.bz2";
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
    sed -i 's|"${env.JAVACMD}" |"${env.JAVACMD}" -Xnocompact -Xnoinlining |' bootstrap.sh
    sed -i 's/depends="jars,test-jar"/depends="jars"/g' build.xml
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
