package lineageos.providers;

import android.content.ContentResolver;
import android.net.Uri;
import android.provider.Settings;

public final class LineageSettings {
    private LineageSettings() {
    }

    public static final class System {
        public static final String ENABLE_TASKBAR = "enable_taskbar";
        public static final String NAVIGATION_BAR_HINT = "navigation_bar_hint";
        public static final String FORCE_SHOW_NAVBAR = "force_show_navbar";
        public static final Uri CONTENT_URI = Settings.System.CONTENT_URI;

        private System() {
        }

        public static Uri getUriFor(String name) {
            return Settings.System.getUriFor(name);
        }

        public static int getInt(ContentResolver resolver, String name, int def) {
            return Settings.System.getInt(resolver, name, def);
        }
    }
}
