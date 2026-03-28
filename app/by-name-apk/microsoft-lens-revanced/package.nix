{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  revanced-cli,
  revanced-patches,
}:
let
  appPackage =
    let
      microsoftLensApk = fetchurl {
        # APKPure page: https://apkpure.com/microsoft-lens-pdf-scanner/com.microsoft.office.officelens
        name = "microsoft-lens-16.0.19628.20008.apk";
        url = "https://web.archive.org/web/20260325084834if_/https://d-03.winudf.com/b/APK/Y29tLm1pY3Jvc29mdC5vZmZpY2Uub2ZmaWNlbGVuc18yMDA0OTY5Njk5X2JhYTAwYjMz?_fn=TWljcm9zb2Z0IExlbnMgLSBQREYgU2Nhbm5lcl8xNi4wLjE5NjI4LjIwMDA4X0FQS1B1cmUuYXBr&_p=Y29tLm1pY3Jvc29mdC5vZmZpY2Uub2ZmaWNlbGVucw%3D%3D&download_id=1899102524009735&is_hot=true&k=aea447c08538422a3ab6193ea438f98669c4f261";
        hash = "sha256-wbsMm4gbZf+ZjFcpRLb0DJBTH87cKiYIUHwR7ZDN9zI=";
      };

      revancedBundle = "${revanced-patches}/app/revanced/patches/6.1.0/patches-6.1.0.rvp";
    in
    stdenv.mkDerivation {
      pname = "microsoft-lens-revanced";
      version = "16.0.19628.20008-patches-6.1.0";

      dontUnpack = true;

      nativeBuildInputs = [
        revanced-cli
      ];

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/microsoft-lens-revanced"
        mkdir -p "$workdir"
        cp ${microsoftLensApk} "$workdir/microsoft-lens.apk"
        chmod u+w "$workdir/microsoft-lens.apk"

        revanced-cli patch \
          -b \
          -p ${revancedBundle} \
          -o "$workdir/microsoft-lens-revanced.apk" \
          "$workdir/microsoft-lens.apk"

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 "$TMPDIR/microsoft-lens-revanced/microsoft-lens-revanced.apk" "$out/microsoft-lens-revanced.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Patched Microsoft Lens APK built with ReVanced patches";
        homepage = "https://github.com/ReVanced/revanced-patches";
        platforms = platforms.unix;
      };
    };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "microsoft-lens-revanced.apk";
  signScriptName = "sign-microsoft-lens-revanced";
  fdroid = {
    appId = "com.microsoft.office.officelens";
    metadataYml = ''
      Categories:
        - Productivity
      License: Proprietary
      SourceCode: https://github.com/ReVanced/revanced-patches
      IssueTracker: https://github.com/ReVanced/revanced-patches/issues
      AutoName: Microsoft Lens ReVanced
      Summary: Patched Microsoft Lens APK
      Description: |-
        Microsoft Lens ReVanced is a patched Microsoft Lens APK built
        with ReVanced patches and kept under the original package name.
    '';
  };
}
