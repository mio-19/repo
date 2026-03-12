{ axp_kernel_patches }:
/*
  Derived from:
  - https://git.disroot.org/AXP.OS/build/raw/branch/axp/Scripts/LineageOS-22.2/CVE_Patchers/android_kernel_oneplus_sdm845.sh
  - https://git.disroot.org/AXP.OS/kernel_patches at commit
    3aa8873aa23dcac8469b02684093c4c025500f20

  Selection method:
  - start from the AXP.OS sdm845 script entries relevant to the LineageOS
    enchilada kernel tree (4.9.337)
  - keep only patches that pass git apply --check against the local patched
    kernel source used by this repo
  - then re-apply that reduced list sequentially in upstream order and keep the
    cumulative series that still applies cleanly
  - exclude subtree-only patches that need git apply --directory=... because
    nix-kernelsu-builder's kernelPatches hook applies patches from repo root
*/
let
  mkAxpPatch = rel: axp_kernel_patches + "/${rel}";
in
map mkAxpPatch [
  "0002-Misc_Fixes-Steam/4.14/0002.patch"
  "0005-Graphene-Deny_USB/4.9/0002.patch"
  "0008-Graphene-Kernel_Hardening-allocsize/4.9/0001.patch"
  "0008-Graphene-Kernel_Hardening-allocsize/4.9/0015.patch"
  "0008-Graphene-Kernel_Hardening-allocsize/4.9/0020.patch"
  "0008-Graphene-Kernel_Hardening-bugon/4.9/0004.patch"
  "0008-Graphene-Kernel_Hardening-bugon/4.9/0009.patch"
  "0008-Graphene-Kernel_Hardening-misc/4.9/0009.patch"
  "0008-Graphene-Kernel_Hardening-misc/4.9/0017.patch"
  "0008-Graphene-Kernel_Hardening-misc/4.9/0020.patch"
  "0008-Graphene-Kernel_Hardening-random/4.9/0001.patch"
  "0008-Graphene-Kernel_Hardening-random/4.9/0006.patch"
  "0008-Graphene-Kernel_Hardening-random/4.9/0011.patch"
  "0008-Graphene-Kernel_Hardening-random/4.9/0016.patch"
  "0008-Graphene-Kernel_Hardening-ro/4.9/0001.patch"
  "0008-Graphene-Kernel_Hardening-ro/4.9/0011.patch"
  "0008-Graphene-Kernel_Hardening-ro/4.9/0027.patch"
  "0008-Graphene-Kernel_Hardening-ro/4.9/0031.patch"
  "0008-Graphene-Kernel_Hardening-sanitize/4.9/0002.patch"
  "0008-Graphene-Kernel_Hardening-sanitize/4.9/0004.patch"
  "0008-Graphene-Kernel_Hardening-slab/4.9/0002.patch"
  "0008-Graphene-Kernel_Hardening-slab/4.9/0009.patch"
  "0008-Graphene-Kernel_Hardening-slab/4.9/0013.patch"
  "0008-Graphene-Kernel_Hardening-slab/4.9/0017.patch"
  "0008-Graphene-Kernel_Hardening-slub/4.9/0004.patch"
  "0008-Graphene-Kernel_Hardening-slub/4.9/0006.patch"
  "0008-Graphene-Kernel_Hardening-slub/4.9/0008.patch"
  "CVE-2015-7837/ANY/0001.patch"
  "CVE-2016-3695/ANY/0001.patch"
  "CVE-2018-5897/ANY/0001.patch"
  "CVE-2019-15291/4.9/0007.patch"
  "CVE-2019-19051/4.9/0013.patch"
  "CVE-2019-19068/4.9/0005.patch"
  "CVE-2021-47173/4.9/0006.patch"
  "CVE-2022-48966/4.9/0004.patch"
  "CVE-2024-1086-alt/4.9/0008.patch"
]
