#!/bin/bash
for pkg in weathermaster ytdlnis haven gamenative forkgram-classic meditrak kdeconnect-android mastodon-android rain; do
    echo "Updating deps for $pkg..."
    # Check if it has a mitmCache.updateScript
    script=$(nix build .#apk_$pkg.mitmCache.updateScript --no-link --print-out-paths 2>/dev/null)
    if [ -n "$script" ]; then
        echo "Running $script for $pkg..."
        "$script"
    else
        echo "$pkg does not have mitmCache.updateScript"
        # Check if it has gradle2nix lock script or something
        if [ -d "app/apks/$pkg" ] && [ -f "app/apks/$pkg/gradle.lock" ]; then
            echo "$pkg uses gradle.lock, let's see if we can update it"
            # It might be in the app directory, let's just log it for now
            # Typically gradle.lock is updated via gradle2nix
            echo "Need manual gradle2nix for $pkg"
        fi
    fi
done
