{
  lib,
  stdenv,
  fetchurl,
  unzip,
  bootstrap-jdk-stage1,
  gnu-classpath-0_93,
}:
stdenv.mkDerivation rec {
  pname = "ecj-bootstrap";
  version = "3.2.2";

  src = fetchurl {
    url = "http://archive.eclipse.org/eclipse/downloads/drops/R-3.2.2-200702121330/ecjsrc.zip";
    sha256 = "05hj82kxd23qaglsjkaqcj944riisjha7acf7h3ljhrjyljx8307";
  };

  nativeBuildInputs = [
    unzip
    bootstrap-jdk-stage1
  ];

  unpackPhase = ''
    unzip $src
  '';

  buildPhase = ''
    mkdir -p build
    rm -f org/eclipse/jdt/core/JDTCompilerAdapter.java
    find . -name "*.java" > sources.txt
    # ECJ 3.2.2 is old enough that it should work with Jikes (via bootstrap-jdk-stage1)
    javac -d build @sources.txt
    
    # Copy resource files
    find . -name "*.properties" -exec cp --parents {} build/ \;
    find . -name "*.rsc" -exec cp --parents {} build/ \;
  '';

  installPhase = ''
    mkdir -p $out/share/java $out/bin
    (cd build && jar cf $out/share/java/ecj-bootstrap.jar *)
    
    # Create a javac wrapper using ecj-bootstrap
    cat > $out/bin/javac <<EOF
#!/bin/sh
exec ${bootstrap-jdk-stage1}/bin/java -cp $out/share/java/ecj-bootstrap.jar org.eclipse.jdt.internal.compiler.batch.Main -bootclasspath ${gnu-classpath-0_93}/share/classpath/glibj.zip -nowarn -1.5 "\$@"
EOF
    chmod +x $out/bin/javac
  '';

  meta = with lib; {
    description = "Eclipse Compiler for Java (bootstrap version)";
    homepage = "https://www.eclipse.org/jdt/core/";
    license = licenses.epl10;
    platforms = platforms.linux;
  };
}
