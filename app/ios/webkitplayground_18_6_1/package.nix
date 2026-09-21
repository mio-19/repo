{ webkitplayground }:

# Custom WebKit rootless .deb for iOS 18.6.1 (iPhone 11) + patched Dopamine.
#   nix build .#ios_webkitplayground_18_6_1
webkitplayground.override { targetIOS = "18.6.1"; }
