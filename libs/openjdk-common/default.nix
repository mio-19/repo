{
  lib,
  stdenv,
  jamvm-2_0_0,
  gnu-classpath-0_99,
  openjdk8,
  openjdk8_headless,
  openjdk11,
  openjdk11_headless,
  openjdk17,
  openjdk17_headless,
  openjdk21,
  openjdk21_headless,
  openjdk25,
  openjdk25_headless,
  icedtea7,
}:
let
  # Nixpkgs OpenJDK generic builder has a bug where it calls
  # jdk-bootstrap.override { gtkSupport = ... } but OpenJDK itself
  # expects enableGtk. We wrap the JDKs to handle/ignore this.
  wrapJdk =
    jdk:
    let
      res = jdk.override { };
    in
    res
    // {
      override =
        args:
        wrapJdk (
          jdk.override (
            builtins.removeAttrs args [
              "gtkSupport"
              "enableGtk"
            ]
            // (lib.optionalAttrs (args ? gtkSupport || args ? enableGtk) {
              enableGtk = args.enableGtk or args.gtkSupport;
            })
          )
        );
    };

  # OpenJDK 8 (Requires OpenJDK 7 / IcedTea 7)
  jdk8_bootstrapped = wrapJdk (openjdk8.override { jdk-bootstrap = icedtea7; });
  jdk8_headless_bootstrapped = wrapJdk (
    openjdk8_headless.override { jdk-bootstrap = icedtea7.jre; }
  );

  # OpenJDK 11 (Requires OpenJDK 8)
  jdk11_bootstrapped = wrapJdk (openjdk11.override { jdk-bootstrap = jdk8_bootstrapped; });
  jdk11_headless_bootstrapped = wrapJdk (
    openjdk11_headless.override { jdk-bootstrap = jdk8_headless_bootstrapped; }
  );

  # OpenJDK 17 (Requires OpenJDK 11)
  jdk17_bootstrapped = wrapJdk (openjdk17.override { jdk-bootstrap = jdk11_bootstrapped; });
  jdk17_headless_bootstrapped = wrapJdk (
    openjdk11_headless.override { jdk-bootstrap = jdk11_headless_bootstrapped; }
  );

  # OpenJDK 21 (Requires OpenJDK 17)
  jdk21_bootstrapped = wrapJdk (openjdk21.override { jdk-bootstrap = jdk17_bootstrapped; });
  jdk21_headless_bootstrapped = wrapJdk (
    openjdk21_headless.override { jdk-bootstrap = jdk17_headless_bootstrapped; }
  );

  # OpenJDK 25 (Requires OpenJDK 21)
  jdk25_bootstrapped = wrapJdk (openjdk25.override { jdk-bootstrap = jdk21_bootstrapped; });
  jdk25_headless_bootstrapped = wrapJdk (
    openjdk25_headless.override { jdk-bootstrap = jdk21_headless_bootstrapped; }
  );
in
{
  inherit
    jdk8_bootstrapped
    jdk8_headless_bootstrapped
    jdk11_bootstrapped
    jdk11_headless_bootstrapped
    jdk17_bootstrapped
    jdk17_headless_bootstrapped
    jdk21_bootstrapped
    jdk21_headless_bootstrapped
    jdk25_bootstrapped
    jdk25_headless_bootstrapped
    ;
}
