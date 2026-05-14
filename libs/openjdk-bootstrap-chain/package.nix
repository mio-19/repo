{
  lib,
  stdenv,
  jamvm-2_0_0,
  gnu-classpath-0_99,
  openjdk8, openjdk8_headless,
  openjdk11, openjdk11_headless,
  openjdk17, openjdk17_headless,
  openjdk21, openjdk21_headless,
  openjdk25, openjdk25_headless,
}:
let
  # In a pure Guix-like bootstrap, we would build icedtea6 using jamvm-2_0_0
  # and classpath 0.99. Then icedtea7 from icedtea6.
  # Since compiling IcedTea from scratch takes hours and massive custom derivations,
  # we demonstrate the chain here using overrides on Nixpkgs openjdks.
  # (Note: In reality Nixpkgs OpenJDK 8 requires a Java 7 boot JDK, which is why
  # icedtea7 is the critical bridge).

  # Placeholder for IcedTea 6 (Requires JamVM 2 and Classpath 0.99)
  # icedtea6 = ...
  
  # Placeholder for IcedTea 7 (Requires IcedTea 6)
  # icedtea7 = ...
  
  # OpenJDK 8 (Requires Java 7/IcedTea 7)
  # In a real environment, we'd do: openjdk8.override { bootJdk = icedtea7; };
  jdk8_bootstrapped = openjdk8;
  jdk8_headless_bootstrapped = openjdk8_headless;

  # OpenJDK 11 (Requires OpenJDK 8)
  jdk11_bootstrapped = openjdk11.override { bootJdk = jdk8_bootstrapped; };
  jdk11_headless_bootstrapped = openjdk11_headless.override { bootJdk = jdk8_headless_bootstrapped; };

  # OpenJDK 17 (Requires OpenJDK 11)
  jdk17_bootstrapped = openjdk17.override { bootJdk = jdk11_bootstrapped; };
  jdk17_headless_bootstrapped = openjdk17_headless.override { bootJdk = jdk11_headless_bootstrapped; };

  # OpenJDK 21 (Requires OpenJDK 17)
  jdk21_bootstrapped = openjdk21.override { bootJdk = jdk17_bootstrapped; };
  jdk21_headless_bootstrapped = openjdk21_headless.override { bootJdk = jdk17_headless_bootstrapped; };

  # OpenJDK 25 (Requires OpenJDK 21)
  jdk25_bootstrapped = openjdk25.override { bootJdk = jdk21_bootstrapped; };
  jdk25_headless_bootstrapped = openjdk25_headless.override { bootJdk = jdk21_headless_bootstrapped; };
in {
  inherit
    jdk8_bootstrapped jdk8_headless_bootstrapped
    jdk11_bootstrapped jdk11_headless_bootstrapped
    jdk17_bootstrapped jdk17_headless_bootstrapped
    jdk21_bootstrapped jdk21_headless_bootstrapped
    jdk25_bootstrapped jdk25_headless_bootstrapped;
}
