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
    makeWrapper ${jamvm-1_5_1}/bin/jamvm $out/bin/java \
      --add-flags "-Xbootclasspath:${gnu-classpath-0_93}/share/classpath/glibj.zip:${jamvm-1_5_1}/share/jamvm/classes.zip"

    # The "jar" for this stage is gjar from gnu-classpath
    ln -s ${gnu-classpath-0_93}/bin/gjar $out/bin/jar
  '';

  passthru = {
    home = "${placeholder "out"}";
  };
}
