with import <nixpkgs> {};
let
  s = androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "8.0";
    toolsVersion = "26.1.1";
    platformToolsVersion = "35.0.1";
    buildToolsVersions = [ "35.0.0" "36.0.0" ];
    includeEmulator = false;
    includeEmulatorSystemImages = false;
    includeSystemImages = false;
    includeSources = false;
    includeNdk = false;
    useGoogleAPIs = false;
    useGoogleTVAddOns = false;
  };
in
  s.androidsdk
