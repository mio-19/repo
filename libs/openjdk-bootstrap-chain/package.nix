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

  # To ensure these all build in this environment, we use the standard Nixpkgs
  # bootstrap JDKs (which are often pre-built binaries).
  # In a full-source bootstrap (like Guix), these would eventually be replaced
  # by our own compiled versions once the IcedTea bridge is implemented.

  jdk8_bootstrapped = wrapJdk openjdk8;
  jdk8_headless_bootstrapped = wrapJdk openjdk8_headless;

  jdk11_bootstrapped = wrapJdk (
    openjdk11.override { jdk-bootstrap = openjdk11.passthru.jdk-bootstrap; }
  );
  jdk11_headless_bootstrapped = wrapJdk (
    openjdk11_headless.override { jdk-bootstrap = openjdk11_headless.passthru.jdk-bootstrap; }
  );

  jdk17_bootstrapped = wrapJdk (
    openjdk17.override { jdk-bootstrap = openjdk17.passthru.jdk-bootstrap; }
  );
  jdk17_headless_bootstrapped = wrapJdk (
    openjdk17_headless.override { jdk-bootstrap = openjdk17_headless.passthru.jdk-bootstrap; }
  );

  jdk21_bootstrapped = wrapJdk (
    openjdk21.override { jdk-bootstrap = openjdk21.passthru.jdk-bootstrap; }
  );
  jdk21_headless_bootstrapped = wrapJdk (
    openjdk21_headless.override { jdk-bootstrap = openjdk21_headless.passthru.jdk-bootstrap; }
  );

  jdk25_bootstrapped = wrapJdk (
    openjdk25.override { jdk-bootstrap = openjdk25.passthru.jdk-bootstrap; }
  );
  jdk25_headless_bootstrapped = wrapJdk (
    openjdk25_headless.override { jdk-bootstrap = openjdk25_headless.passthru.jdk-bootstrap; }
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
