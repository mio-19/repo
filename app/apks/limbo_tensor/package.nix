{
  mk-apk-package,
  stdenvNoCC,
  lib,
  fetchurl,
}:
let
  version = "0.5.0";
  appPackage = stdenvNoCC.mkDerivation {
    pname = "limbo-tensor";
    inherit version;
    src = fetchurl {
      url = "https://github.com/wasdwasd0105/limbo_tensor/releases/download/v${version}/limbo-kvm-release-${version}.apk";
      hash = "sha256-xK9tWv70hD/NFBa5KwvNIBUtqAe/RYEfxWgjlBtI4Eg=";
    };
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      install -Dm644 "$src" "$out/limbo-tensor.apk"
      runHook postInstall
    '';
    meta = with lib; {
      description = "QEMU and KVM virtual machine manager for Tensor devices";
      homepage = "https://github.com/wasdwasd0105/limbo_tensor";
      license = licenses.gpl2Only;
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "limbo-tensor.apk";
  signScriptName = "sign-limbo-tensor";
  fdroid = {
    appId = "com.limbo.emu.main.arm";
    metadataYml = ''
      Categories:
        - System
      License: GPL-2.0-only
      SourceCode: https://github.com/wasdwasd0105/limbo_tensor
      IssueTracker: https://github.com/wasdwasd0105/limbo_tensor/issues
      AutoName: Limbo Tensor
      Summary: QEMU and KVM virtual machines on Tensor devices
      Description: |-
        A Limbo QEMU virtual machine manager for Google Tensor devices.
        The v${version} release APK supplies the QEMU 7.2 runtime and UTM
        ramfb support; the repository source archive does not include those
        native runtime sources.
    '';
  };
}
