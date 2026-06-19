# Minimal install wrapper for source-built Ant versions.
# The old vendored nixpkgs copy shipped a binary tarball plus gitUpdater and
# binary-only metadata that source-built overrides never use.
{
  lib,
  stdenv,
  coreutils,
  makeWrapper,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ant";
  version = "1.10.17";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/ant
    mv * $out/share/ant/

    # Keep antRun for the <exec/> task, but provide our own ant launcher.
    mv $out/share/ant/bin/antRun $out/bin/
    rm -rf $out/share/ant/{manual,bin,WHATSNEW}
    mkdir $out/share/ant/bin
    mv $out/bin/antRun $out/share/ant/bin/

    cat >> $out/bin/ant <<EOF
    #! ${stdenv.shell} -e

    ANT_HOME=$out/share/ant

    if [ -z "\''${JAVA_HOME-}" ]; then
        for i in javac java gij; do
            if p="\$(type -p \$i)"; then
                export JAVA_HOME="\$(${coreutils}/bin/dirname \$(${coreutils}/bin/dirname \$(${coreutils}/bin/readlink -f \$p)))"
                break
            fi
        done
        if [ -z "\''${JAVA_HOME-}" ]; then
            echo "\$0: cannot find the JDK or JRE" >&2
            exit 1
        fi
    fi

    if [ -z \$NIX_JVM ]; then
        if [ -e \$JAVA_HOME/bin/java ]; then
            NIX_JVM=\$JAVA_HOME/bin/java
        elif [ -e \$JAVA_HOME/bin/gij ]; then
            NIX_JVM=\$JAVA_HOME/bin/gij
        else
            NIX_JVM=java
        fi
    fi

    LOCALCLASSPATH="\$ANT_HOME/lib/ant-launcher.jar\''${LOCALCLASSPATH:+:}\$LOCALCLASSPATH"

    if [ -n "\$ANT_LIB" ]; then
        ANT_LIB_ARG="-Dant.library.dir=\$ANT_LIB"
    fi

    exec \$NIX_JVM \$NIX_ANT_OPTS \$ANT_OPTS -classpath "\$LOCALCLASSPATH" \\
        -Dant.home=\$ANT_HOME \''${ANT_LIB_ARG:+"\$ANT_LIB_ARG"} \\
        org.apache.tools.ant.launch.Launcher \$NIX_ANT_ARGS \$ANT_ARGS \\
        -cp "\$CLASSPATH" "\$@"
    EOF

    chmod +x $out/bin/ant

    runHook postInstall
  '';

  passthru = {
    home = "${finalAttrs.finalPackage}/share/ant";
  };

  meta = {
    homepage = "https://ant.apache.org/";
    description = "Java-based build tool";
    mainProgram = "ant";
    license = lib.licenses.asl20;
    teams = [ lib.teams.java ];
    platforms = lib.platforms.unix;
  };
})
