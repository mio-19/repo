# Pixel 9 Pro XL: first PWM experiment

Every boot starts in stock mode. The kernel module parameter `pwm_mode`
defaults to `-1`; Android uses the RAM-only
`sys.komodo_high_emission_frequency_mode` property and explicitly resets it to
`off` in `early-boot`. All nine selection triggers require
`sys.boot_completed=1`. The old persistent property is ignored.

The patch changes only CM4/KM4's existing early-exit register byte. It leaves
brightness, matrix compensation, AOD handling, DRM properties, and all other
panel drivers untouched. The previous four-byte experiment and its display
pipeline changes have been removed from the active patch.

## First test

Start with Off as a measured baseline, then select **Mode 0 (first experiment)**.
Cycle the screen off/on to give the panel feature-update path an opportunity
to apply the request. Parameter writes themselves do not send panel commands;
a property readback is not proof of hardware application.

Compare measured PWM at the same brightness and refresh rate. Keep other
settings fixed. Mode 1 writes the stock byte and provides a control. Then test
other modes individually if useful. Check low/high brightness, adaptive
refresh, AOD, fingerprint unlock, and screen off/on. Reboot after a non-Off
selection and verify the property is `off` and the active panel's `pwm_mode`
is `-1`. No experiment selection survives a reboot.

Off restores the stock byte on the next panel feature update. Reboot gives a
fresh stock initialization. Invalid module parameter values also select the
stock byte. No Hz values are claimed without measurement.

## Byte-by-byte reasoning

The pinned upstream CM4/KM4 code uses:

```c
val = (early_exit && vrefresh != 80) ? 0x01 : 0x81;
// B0 00 01 BD
// BD val
```

| Bytes / field | Evidence and decision |
| --- | --- |
| `B0 00 01 BD` | The target driver uses this to select the offset-1 parameter for BD. Preserve it exactly. |
| `BD` | Used by the target driver for early-exit/frame-insertion programming. It is not proven to be exclusively a PWM register. |
| Bit 7 (`80`) | Upstream chooses `01` versus `81` according to early exit and the 80 Hz exception. Preserve that exact condition. |
| Low bits `0`–`7` | Experimental candidates derived from the working Pixel 8 mod. Pixel 9 source establishes only the stock value `1`. Test `0` first; its effect is not proven. |
| `43 43 03` | Present in the Pixel 8 working recipe, but Pixel 9's stock transaction does not write these neighboring bytes. Omit them from the first experiment. |
| `21` prefix | Used in HK3's sequence and elsewhere in Pixel 9 manual frame insertion. It is not established as a portable prefix. Do not add it to the offset-1 transaction. |

The chosen experiment writes `BD 00` where stock would write `BD 01`, or
`BD 80` where stock would write `BD 81`. Other modes replace only the low
three bits. This minimizes assumptions and makes the result easier to
interpret. It might have no beneficial PWM effect: the original Pixel 8 result
applies to the complete four-byte payload, not to this byte in isolation.

There is no justified formula mapping these candidates to Hz. A full
Pixel 8-derived payload can be considered as a later, separate experiment if
this one provides no useful result. Brightness compensation stays absent so
it cannot confound the first measurement.

## Internet sources checked

Primary sources from Hamster Tian (`updateing`), checked 2026-11-08:

- [Original PWM/pixel-on-ratio change](https://github.com/updateing/android_kernel_google_zuma/commit/759e096a6ba39687e0ebe20cf5845ecf69632868).
  The author describes trial-and-error discovery and camera observation, not
  a decoded register specification. This establishes the origin of the
  `00 43 43 03` recipe and its early-exit-bit handling, but not compatibility
  with KM4. Higher-frequency combinations produced artifacts.
- [AOD reset fix](https://github.com/updateing/android_kernel_google_zuma/commit/60d772c2e51304d1454be922afd4eba02b5c50ca).
  Documents clearing compensation during low-power mode and restoring normal
  dimming on exit to address darkness/flashes. Explains why a later compensation experiment would need explicit AOD cleanup; the first experiment leaves the stock pipeline intact.
- [Sub-120 Hz parameters](https://github.com/updateing/android_kernel_google_zuma/commit/bd3aabffcc91267355505233bc7f89585b7bae43).
  Reports artifacts at lower refresh rates. Supports testing across refresh
  modes instead of treating one frequency label as universally valid.
- [HBM-specific parameters](https://github.com/updateing/android_kernel_google_zuma/commit/ed28a1323b7680b9361a11f371a1c6f686792752).
  Supports treating HBM behavior as a separate validation requirement.
- [Exposure-adjustment rationale](https://github.com/updateing/android_kernel_google_zuma/commit/be9a866889a3a3577b5e647c49f3c1635af38163).
  Explains that the threshold should correspond to the measured duty-cycle
  transition. It does not establish `600` for Pixel 9.
- [Reapply after screen-on](https://github.com/updateing/android_kernel_google_zuma/commit/2d9da86f4bac19a65480172a2a198e23ea0fbc94).
  Explains that unchanged panel features can skip programming. This reinforces
  the limitation that writing a module parameter alone is not hardware
  acknowledgment; screen-cycle behavior needs on-device validation.

The commit contents were retrieved through GitHub's public API, for example
<https://api.github.com/repos/updateing/android_kernel_google_zuma/commits/759e096a6ba39687e0ebe20cf5845ecf69632868>.
The original [XDA thread](https://xdaforums.com/t/a-mod-on-pwm-frequency-v3-20241027.4683727/)
could not be retrieved during this review (HTTP 502); no new byte semantics
are attributed to unread thread content. Searches did not locate a verified
KM4 register specification or an independently validated Pixel 9 payload.

Target source: [GrapheneOS kernel_pixel](https://gitlab.com/grapheneos/kernel_pixel),
tag `2026110200`, as pinned by `gos/kernels/common.nix`. The local fetched source
was used to inspect the exact CM4/KM4 implementation and generate the patch.
