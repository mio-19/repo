{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.meshcore-open;
  mainApk = "meshcore-open.apk";
  signScriptName = "sign-meshcore-open";
  fdroid = {
    appId = "com.meshcore.meshcore_open";
    metadataYml = ''
      Categories:
        - Internet
      License: MIT
      SourceCode: https://github.com/zjs81/meshcore-open
      IssueTracker: https://github.com/zjs81/meshcore-open/issues
      AutoName: MeshCore Open
      Summary: Mesh networking client for MeshCore devices
      Description: |-
        MeshCore Open is an open-source client for MeshCore LoRa mesh
        networking devices, supporting messaging, channels, maps, and
        device management.
    '';
  };
}
