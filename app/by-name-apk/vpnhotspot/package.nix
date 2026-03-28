{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.vpnhotspot;
  mainApk = "vpnhotspot.apk";
  signScriptName = "sign-vpnhotspot";
  fdroid = {
    appId = "be.mygod.vpnhotspot";
    metadataYml = ''
      Categories:
        - Connectivity
        - VPN & Proxy
      License: Apache-2.0
      AuthorName: Mygod Studio
      AuthorEmail: contact-vpnhotspot@mygod.be
      WebSite: https://mygod.be/
      SourceCode: https://github.com/Mygod/VPNHotspot
      IssueTracker: https://github.com/Mygod/VPNHotspot/issues
      Changelog: https://github.com/Mygod/VPNHotspot/releases
      Donate: https://mygod.be/donate/
      AutoName: VPN Hotspot
      Summary: Share VPN connections over hotspot and tethering
      Description: |-
        VPN Hotspot helps share a VPN connection over Wi-Fi hotspot,
        USB tethering, Bluetooth tethering, and related Android
        networking paths.

        This package is built from source and follows the F-Droid
        packaging approach, with Google services removed for a fully
        libre build.
      RequiresRoot: true
    '';
  };
}
