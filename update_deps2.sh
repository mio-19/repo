$(nix build .#apk_forkgram.mitmCache.updateScript --no-link --print-out-paths)
$(nix build .#apk_forkgram-classic.mitmCache.updateScript --no-link --print-out-paths)
$(nix build .#apk_mpv-android.mitmCache.updateScript --no-link --print-out-paths)
