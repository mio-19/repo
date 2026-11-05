# Fairphone 4 experimental mainline build

This experiment builds LineageOS 24.0 Android userspace for FP4 while replacing
the normal 4.19 Android kernel with the Nura/postmarketOS SM6350 mainline kernel
(`v7.2.0-sm6350`). The kernel source and Android build are separately exposed:

```sh
nix build .#fairphone-fp4-mainline-kernel --out-link result-fp4-mainline-kernel -L
nix build .#lineageos-fp4-mainline-img --out-link result-fp4-mainline-img -L
```

`lineageos-fp4-mainline-ota` is also available for build experiments. The
kernel configuration enables Android Binder/BinderFS, SELinux, dm-verity,
fscrypt, storage and Qualcomm display/remoteproc drivers. Its outputs include
`Image.gz`, `sm7225-fairphone-fp4.dtb`, modules and kernel headers.

This is a boot experiment, not a supported or boot-validated ROM. The FP4
proprietary vendor components and Android HALs expect the downstream Qualcomm
4.19 kernel interfaces (including ION, KGSL, audio and WLAN). Supplying the
mainline kernel in the boot image does not port those interfaces. The image can
be useful for measuring the Android build integration, but it is not safe to
flash as a daily-use OS, and no claim is made that it boots, initializes the
modem/cameras, or preserves data. No kernel patches from AXP.OS are applied to
the mainline kernel.

Kernel source: [sm6350-mainline/linux](https://github.com/sm6350-mainline/linux),
GPL-2.0-only. Nura package reference:
[linux-postmarketos-qcom-sm6350](https://pkgs.nura.eco/package/main/postmarketos/aarch64/linux-postmarketos-qcom-sm6350).
