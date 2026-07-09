{
  stdenv,
  runCommand,
  jamvm-2_0_0,
  ecj-bootstrap-4_2_1,
  gnu-classpath-devel,
  fastjar,
}:
let
  jdk5 =
    runCommand "jdk5-jamvm-classpath"
      {
        passthru.home = "${jdk5}";
      }
      ''
        classpathTool() {
          substitute ${../../op/openjdk-common/classpath-tool.sh.in} "$out/bin/$1" \
            --subst-var-by shell "${stdenv.shell}" \
            --subst-var-by java "${jamvm-2_0_0}/bin/jamvm" \
            --subst-var-by classpath "${gnu-classpath-devel}" \
            --subst-var-by toolPkg "$2" \
            --subst-var-by mainClass "$3"
          chmod +x "$out/bin/$1"
        }

        mkdir -p $out/bin $out/include/linux $out/lib $out/jre/lib

        classpathTool javah javah Main
        classpathTool rmic rmic Main
        classpathTool rmid rmid Main
        classpathTool orbd orbd Main
        classpathTool rmiregistry rmiregistry Main
        classpathTool native2ascii native2ascii Native2ASCII

        printf '#!%s\nexec %s -Djava.home=%s "$@"\n' \
          "${stdenv.shell}" "${jamvm-2_0_0}/bin/jamvm" "$out" > $out/bin/java
        chmod +x $out/bin/java

        ln -s ${ecj-bootstrap-4_2_1}/bin/javac $out/bin/javac
        ln -s ${fastjar}/bin/fastjar $out/bin/jar
        ln -s ${gnu-classpath-devel}/include/*.h $out/include/
        ln -s ${gnu-classpath-devel}/include/*_md.h $out/include/linux/
        ln -s ${gnu-classpath-devel}/share/classpath/tools.zip $out/lib/tools.jar
        ln -s ${gnu-classpath-devel}/share/classpath/glibj.zip $out/jre/lib/rt.jar
      '';
in
jdk5
