{
  lib,
  stdenv,
  fetchFromGitHub,
  bootstrap-jdk-stage1,
  ecj-bootstrap-3_2_2,
}:
stdenv.mkDerivation rec {
  pname = "ant-bootstrap";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "ant";
    rev = "ANT_170";
    hash = "sha256-ogmusUIWXPMakblTP3FuvN7R4BLn06ha0BKPuGi6Py4=";
  };

  nativeBuildInputs = [ bootstrap-jdk-stage1 ecj-bootstrap-3_2_2 ];

  buildPhase = ''
    export JAVA_HOME=${bootstrap-jdk-stage1}
    export JAVACMD=${bootstrap-jdk-stage1}/bin/java
    export JAVAC=${ecj-bootstrap-3_2_2}/bin/javac
    export PATH=${ecj-bootstrap-3_2_2}/bin:$PATH
    export HOME=$TMPDIR
    
    chmod +x build.sh
    export ANT_OPTS="-Xnocompact -Xnoinlining -Xms128m -Xmx512m -Dbuild.compiler=extJavac"
    export BOOTJAVAC_OPTS="-nowarn -sourcepath src/main"
    
    # Prevent JamVM segmentation fault by disabling some optimizations
    sed -i 's|"''${JAVACMD}" |"''${JAVACMD}" -Xnocompact -Xnoinlining |g' build.sh
    
    # Disable building tests to avoid compilation errors with Jikes
    sed -i 's/depends="jars,test-jar"/depends="jars"/g' build.xml
    
    # build.sh dist creates the distribution in the specified directory
    sh build.sh -Ddist.dir=$out dist
  '';

  installPhase = ''
    # The distribution is already built and placed in $out
    # Let's ensure the bin directory exists and has the ant executable
    test -d $out/bin || exit 1
  '';

  meta = with lib; {
    description = "Apache Ant, a Java-based build tool (bootstrap version)";
    homepage = "https://ant.apache.org/";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
