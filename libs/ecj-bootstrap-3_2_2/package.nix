{
  lib,
  stdenv,
  fetchzip,
  jikes,
  fastjar,
  jamvm-1_5_1,
  ant-bootstrap,
  gnu-classpath-0_93,
}:
stdenv.mkDerivation rec {
  pname = "ecj-bootstrap";
  version = "3.2.2";

  src = fetchzip {
    stripRoot = false;
    url = "http://archive.eclipse.org/eclipse/downloads/drops/R-${version}-200702121330/ecjsrc.zip";
    hash = "sha256-Hdt/yYaZOQOV8bKIQz+xouX8iPr2eV3z6zh9R376I3o=";
  };

  env.CLASSPATH = "${jamvm-1_5_1}/lib/rt.jar:${
    lib.concatStringsSep ":" (
      map (j: "${ant-bootstrap}/lib/${j}") [
        "ant-antlr.jar"
        "ant-apache-bcel.jar"
        "ant-apache-bsf.jar"
        "ant-apache-log4j.jar"
        "ant-apache-oro.jar"
        "ant-apache-regexp.jar"
        "ant-apache-resolver.jar"
        "ant-apache-xalan2.jar"
        "ant-commons-logging.jar"
        "ant-commons-net.jar"
        "ant-jai.jar"
        "ant-javamail.jar"
        "ant-jdepend.jar"
        "ant-jmf.jar"
        "ant-jsch.jar"
        "ant-junit.jar"
        "ant-junit4.jar"
        "ant-launcher.jar"
        "ant-netrexx.jar"
        "ant-swing.jar"
        "ant.jar"
      ]
    )
  }";

  nativeBuildInputs = [
    jikes
    fastjar
  ];

  buildPhase = ''
    echo > manifest "Manifest-Version: 1.0
    Main-Class: org.eclipse.jdt.internal.compiler.batch.Main
    "
    jikes $(find . -name "*.java")
    fastjar cvfm ecj-bootstrap.jar manifest .
  '';

  installPhase = ''
    mkdir -p $out/share/java $out/bin
    cp ecj-bootstrap.jar $out/share/java

    # Use the template to create javac wrapper
    substitute ${./ecj-javac.sh.in} $out/bin/javac \
      --subst-var-by shell "${stdenv.shell}" \
      --subst-var-by java "${jamvm-1_5_1}/bin/jamvm" \
      --subst-var-by ecjJar $out/share/java/ecj-bootstrap.jar \
      --subst-var-by bootClasspath "${gnu-classpath-0_93}/share/classpath/glibj.zip:${gnu-classpath-0_93}/share/classpath/tools.zip"
    chmod +x $out/bin/javac
  '';

  meta = with lib; {
    description = "Eclipse Compiler for Java (bootstrap version)";
    homepage = "https://www.eclipse.org/jdt/core/";
    license = licenses.epl10;
    platforms = platforms.linux;
  };
}
