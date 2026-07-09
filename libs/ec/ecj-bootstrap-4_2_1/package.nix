{
  lib,
  stdenv,
  fetchurl,
  unzip,
  zip,
  ant-bootstrap,
  gnu-classpath-devel,
  jamvm-2_0_0,
  ecj-bootstrap-3_2_2,
}:

stdenv.mkDerivation rec {
  pname = "ecj-bootstrap";
  version = "4.2.1";

  src = fetchurl {
    url = "http://archive.eclipse.org/eclipse/downloads/drops4/R-${version}-201209141800/ecjsrc-${version}.jar";
    sha256 = "1x281p87m14zylvinkiz6gc23ss7pzlx419qjbql11jriwav4qfj";
  };

  nativeBuildInputs = [
    unzip
    zip
    ecj-bootstrap-3_2_2
  ];

  env.CLASSPATH = "${gnu-classpath-devel}/share/classpath/glibj.zip:${gnu-classpath-devel}/share/classpath/tools.zip:${
    lib.concatStringsSep ":" (
      map (j: "${ant-bootstrap}/lib/${j}") [
        "ant-antlr.jar"
        "ant-apache-bcel.jar"
        "ant-apache-bsf.jar"
        "ant-apache-log4j.jar"
        "ant-apache-oro.jar"
        "ant-apache-regexp.jar"
        "ant-apache-resolver.jar"
        "ant-commons-logging.jar"
        "ant-commons-net.jar"
        "ant-junit.jar"
        "ant-launcher.jar"
        "ant.jar"
      ]
    )
  }";

  unpackPhase = ''
    runHook preUnpack
    mkdir source
    unzip -q "$src" -d source
    cd source
    runHook postUnpack
  '';

  postPatch = ''
    while IFS= read -r file; do
      substituteInPlace "$file" --replace-fail '@Override' ""
    done < <(grep -rl '@Override' .)
  '';

  buildPhase = ''
    runHook preBuild

    rm org/eclipse/jdt/core/JDTCompilerAdapter.java
    rm -r org/eclipse/jdt/internal/antadapter

    mkdir -p META-INF
    printf 'Manifest-Version: 1.0\nMain-Class: org.eclipse.jdt.internal.compiler.batch.Main\n' > META-INF/MANIFEST.MF

    javac \
      -bootclasspath "${gnu-classpath-devel}/share/classpath/glibj.zip:${gnu-classpath-devel}/share/classpath/tools.zip" \
      $(find . -name '*.java' | sort)

    find . -exec touch -h -d @0 {} +
    zip -0 -X -q ecj-bootstrap.jar META-INF/MANIFEST.MF
    find . -type f ! -path './META-INF/MANIFEST.MF' -print0 | sort -z | xargs -0 zip -0 -X -q ecj-bootstrap.jar

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/java $out/bin
    cp ecj-bootstrap.jar $out/share/java

    substitute ${../ecj-bootstrap-3_2_2/ecj-javac.sh.in} $out/bin/javac \
      --subst-var-by shell "${stdenv.shell}" \
      --subst-var-by java "${jamvm-2_0_0}/bin/jamvm" \
      --subst-var-by ecjJar "$out/share/java/ecj-bootstrap.jar" \
      --subst-var-by bootClasspath "${gnu-classpath-devel}/share/classpath/glibj.zip:${gnu-classpath-devel}/share/classpath/tools.zip"
    chmod +x $out/bin/javac

    runHook postInstall
  '';

  meta = with lib; {
    description = "Eclipse Compiler for Java 4 bootstrap";
    homepage = "https://www.eclipse.org/jdt/core/";
    license = licenses.epl10;
    platforms = platforms.linux;
  };
}
