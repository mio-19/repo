{ callPackage, ... }:
let
  appPackage = callPackage (
    {
      lib,
      stdenv,
      fetchurl,
      revanced-cli,
      revanced-patches,
    }:
    let
      facebookApk = fetchurl {
        # APKPure page: https://apkpure.com/facebook-app/com.facebook.katana/download/490.0.0.63.82
        name = "facebook-490.0.0.63.82.apk";
        url = "https://web.archive.org/web/20260325085949if_/https://d-11.winudf.com/b/APK/Y29tLmZhY2Vib29rLmthdGFuYV80NTcyMTU2MDRfZTc1MWQxZWM?_fn=RmFjZWJvb2tfNDkwLjAuMC42My44Ml9BUEtQdXJlLmFwaw&_p=Y29tLmZhY2Vib29rLmthdGFuYQ%3D%3D&download_id=otr_1481206750421645&is_hot=false&k=786c393c3cac2d6882b1b7378d6eb38069c4f536&uu=http%3A%2F%2F172.16.77.1%2Fb%2FAPK%2FY29tLmZhY2Vib29rLmthdGFuYV80NTcyMTU2MDRfZTc1MWQxZWM%3Fk%3Dcf0c7730fc9a9d0e3a0f9dc416376de269c4f536";
        hash = "sha256-bwuQHwOvXFEdkjOLEXmoQRVC4Gz05rnhUbkL5PPik3E=";
      };

      revancedBundle = "${revanced-patches}/app/revanced/patches/6.1.0/patches-6.1.0.rvp";
    in
    stdenv.mkDerivation {
      pname = "facebook-revanced";
      version = "490.0.0.63.82-patches-6.1.0";

      dontUnpack = true;

      nativeBuildInputs = [
        revanced-cli
      ];

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/facebook-revanced"
        mkdir -p "$workdir"
        cp ${facebookApk} "$workdir/facebook.apk"
        chmod u+w "$workdir/facebook.apk"

        revanced-cli patch \
          -b \
          -p ${revancedBundle} \
          -o "$workdir/facebook-revanced.apk" \
          "$workdir/facebook.apk"

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 "$TMPDIR/facebook-revanced/facebook-revanced.apk" "$out/facebook-revanced.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Patched Facebook APK built with ReVanced patches";
        homepage = "https://github.com/ReVanced/revanced-patches";
        platforms = platforms.unix;
      };
    }
  ) { };
in
callPackage ../../by-name/mk-apk-package/package.nix {
  inherit appPackage;
  mainApk = "facebook-revanced.apk";
  signScriptName = "sign-facebook-revanced";
  fdroid = {
    appId = "com.facebook.katana";
    metadataYml = ''
      Categories:
        - Internet
      License: Proprietary
      SourceCode: https://github.com/ReVanced/revanced-patches
      IssueTracker: https://github.com/ReVanced/revanced-patches/issues
      AutoName: Facebook ReVanced
      Summary: Patched Facebook APK
      Description: |-
        Facebook ReVanced is a patched Facebook APK built with
        ReVanced patches and kept under the original package name.
    '';
  };
}
