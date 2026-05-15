# This bootstrap JDK is inspired by the "Full Source Bootstrap" method used by GNU Guix.
# It uses Jikes (C++), GNU Classpath 0.93, and JamVM 1.5.1 to create a
# minimal JDK that can then be used to build older versions of Ant, ECJ,
# and eventually OpenJDK.
{
  lib,
  stdenv,
  jikes,
  jamvm-1_5_1,
  gnu-classpath-0_93,
  makeWrapper,
}:
stdenv.mkDerivation {
  pname = "bootstrap-jdk";
  version = "stage1";

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    # The "javac" for this stage is jikes
    # We need to point it to the standard classes
    makeWrapper ${jikes}/bin/jikes $out/bin/javac \
      --add-flags "-bootclasspath ${gnu-classpath-0_93}/share/classpath/glibj.zip:${jamvm-1_5_1}/share/jamvm/classes.zip"

    # The "java" for this stage is jamvm
    ln -s ${jamvm-1_5_1}/bin/jamvm $out/bin/java

    # The "jar" for this stage is a wrapper around gnu.classpath.tools.jar.Main
    # since gjar from gnu-classpath assumes jamvm is in its own bin directory.
    cat > $out/bin/jar <<EOF
#!/bin/sh
exec ${jamvm-1_5_1}/bin/jamvm -Xbootclasspath/p:"${gnu-classpath-0_93}/share/classpath/tools.zip" gnu.classpath.tools.jar.Main "\$@"
EOF
    chmod +x $out/bin/jar
  '';

  passthru = {
    home = "${placeholder "out"}";
  };
}
