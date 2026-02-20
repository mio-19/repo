# kernel

## husky kernel

prefer pixel8pro-stock-fix-3840Hz.patch with pixel8pro-lindroid.patch

+ <https://grapheneos.org/build#prebuilt-code>
+ <https://github.com/updateing/android_kernel_google_zuma/commits/14.0.0-sultan-pwm/>
+ <https://xdaforums.com/t/a-mod-on-pwm-frequency-v3-20241027.4683727/>
+ <https://xdaforums.com/t/a-mod-on-pwm-frequency-v3-20241027.4683727/post-89634948>
+ <https://xdaforums.com/t/a-mod-on-pwm-frequency-v3-20241027.4683727/page-8#post-89915781>

adjusted patch from sultan branch <https://github.com/updateing/android_kernel_google_zuma.git> 14.0.0-sultan-pwm: pixel8pro-14.0.0-sultan-pwm.patch

adjusted patch with  Stock-based variant: pixel8pro-stock.patch with kernel crash fix: pixel8pro-stock-fix.patch - pixel8pro-14.0.0-sultan-pwm.patch and pixel8pro-stock.patch don't have actual code difference; pixel8pro-stock-fix-3840Hz.patch

adjusted patch from <https://github.com/elephant-43/kernel_google-modules_display_samsung> <https://github.com/elephant-43/kernel_devices_google_shusky> pixel8pro-elephant-43.patch with kernel crash fix: pixel8pro-elephant-43-fix.patch

adjusted patch from <https://github.com/elephant-43/kernel_google-modules_display> <https://github.com/elephant-43/kernel_devices_google_shusky> pixel8pro-elephant-43-b.patch (not that different from pixel8pro-elephant-43.patch) TODO: correct this patch

```zsh
sudo apt install libssl-dev
KLEAF_REPO_MANIFEST=aosp_manifest.xml ./build_shusky.sh --lto=full
```

lindroid extra steps - pixel8pro-lindroid.patch

```zsh
git clone https://github.com/Linux-on-droid/lindroid-drm-loopback.git aosp/drivers/lindroid-drm
echo 'obj-y += lindroid-drm/' >> aosp/drivers/Makefile
sed -i "/endmenu/i\source \"drivers/lindroid-drm/Kconfig\"" aosp/drivers/Kconfig
tee -a aosp/android/abi_gki_aarch64_pixel << 'EOF'
  make_kuid
  from_kuid
  from_kuid_munged
EOF
```
