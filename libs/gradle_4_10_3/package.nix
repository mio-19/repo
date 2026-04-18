{
  callPackage,
  gradle-packages,
  jdk8_headless,
}:

let
  gradle-unwrapped =
    (gradle-packages.mkGradle {
      version = "4.10.3";
      hash = "sha256-hibL8ga04gGt57h3eQkGkERwVLyT8FKVTHhID6btGG4=";
      defaultJava = jdk8_headless;
    }).overrideAttrs
      {
        dontFixup = true;
        fixupPhase = ":";
      };
in
callPackage gradle-packages.wrapGradle {
  inherit gradle-unwrapped;
}
