import json
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote, urlparse

import yaml


ROOT = Path(".")
PACKAGE_CONFIG = ROOT / ".dart_tool" / "package_config.json"
ROOT_PUBSPEC = ROOT / "pubspec.yaml"
PLUGINS_FILE = ROOT / ".flutter-plugins"
PLUGINS_DEPS_FILE = ROOT / ".flutter-plugins-dependencies"
ANDROID_REGISTRANT = (
    ROOT
    / "android"
    / "app"
    / "src"
    / "main"
    / "java"
    / "io"
    / "flutter"
    / "plugins"
    / "GeneratedPluginRegistrant.java"
)
SKIPPED_PLUGINS = {"integration_test", "flutter_native_splash"}


def load_yaml(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        return yaml.load(handle, Loader=yaml.CSafeLoader) or {}


def package_root(root_uri: str) -> Path:
    parsed = urlparse(root_uri)
    if parsed.scheme in ("", "file"):
        return Path(unquote(parsed.path))
    raise ValueError(f"Unsupported package root URI: {root_uri}")


def plugin_android_config(pubspec: dict):
    flutter = pubspec.get("flutter") or {}
    plugin = flutter.get("plugin")
    if not isinstance(plugin, dict):
        return None

    if "platforms" in plugin and isinstance(plugin["platforms"], dict):
        android = plugin["platforms"].get("android")
        if isinstance(android, dict):
            package = android.get("package")
            plugin_class = android.get("pluginClass")
            ffi_plugin = bool(android.get("ffiPlugin"))
            return {
                "package": package,
                "plugin_class": plugin_class,
                "native_build": bool(package or plugin_class or ffi_plugin),
            }
        if android is not None:
            return {
                "package": None,
                "plugin_class": None,
                "native_build": False,
            }

    if plugin.get("androidPackage") or plugin.get("pluginClass"):
        return {
            "package": plugin.get("androidPackage"),
            "plugin_class": plugin.get("pluginClass"),
            "native_build": True,
        }

    return None


def main() -> None:
    root_pubspec = load_yaml(ROOT_PUBSPEC)
    root_name = root_pubspec["name"]
    dev_dependencies = set((root_pubspec.get("dev_dependencies") or {}).keys())

    with PACKAGE_CONFIG.open("r", encoding="utf-8") as handle:
        package_config = json.load(handle)

    packages = {}
    plugin_names = set()

    for entry in package_config.get("packages", []):
        name = entry["name"]
        if name == root_name or entry.get("rootUri") == "flutter_gen":
            continue
        if name in SKIPPED_PLUGINS:
            continue
        root = package_root(entry["rootUri"])
        pubspec_path = root / "pubspec.yaml"
        if not pubspec_path.exists():
            continue
        pubspec = load_yaml(pubspec_path)
        android = plugin_android_config(pubspec)
        if android is None:
            continue
        dependency_names = list((pubspec.get("dependencies") or {}).keys())
        packages[name] = {
            "name": name,
            "path": str(root),
            "dependencies": dependency_names,
            "dev_dependency": name in dev_dependencies,
            **android,
        }
        plugin_names.add(name)

    android_plugins = []
    dependency_graph = []
    legacy_plugins = []
    registrant_plugins = []

    for name in sorted(plugin_names):
        plugin = packages[name]
        plugin_dependencies = [dep for dep in plugin["dependencies"] if dep in plugin_names]

        android_plugins.append(
            {
                "name": name,
                "path": plugin["path"],
                "dependencies": plugin_dependencies,
                "native_build": plugin["native_build"],
                "dev_dependency": plugin["dev_dependency"],
            }
        )
        dependency_graph.append(
            {
                "name": name,
                "dependencies": plugin_dependencies,
            }
        )

        if plugin["native_build"]:
            legacy_plugins.append(f"{name}={plugin['path']}")
        if plugin["native_build"] and plugin["package"] and plugin["plugin_class"]:
            registrant_plugins.append(plugin)

    if legacy_plugins:
        PLUGINS_FILE.write_text("\n".join(legacy_plugins) + "\n", encoding="utf-8")
    elif PLUGINS_FILE.exists():
        PLUGINS_FILE.unlink()

    plugins_metadata = {
        "info": "This is a generated file; do not edit or check into version control.",
        "plugins": {
            "android": android_plugins,
            "ios": [],
            "linux": [],
            "macos": [],
            "web": [],
            "windows": [],
        },
        "dependencyGraph": dependency_graph,
        "date_created": datetime.now(timezone.utc).isoformat(),
        "version": "nix-generated",
    }
    PLUGINS_DEPS_FILE.write_text(
        json.dumps(plugins_metadata, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    ANDROID_REGISTRANT.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "package io.flutter.plugins;",
        "",
        "import androidx.annotation.Keep;",
        "import androidx.annotation.NonNull;",
        "import io.flutter.Log;",
        "import io.flutter.embedding.engine.FlutterEngine;",
        "",
        "/**",
        " * Generated file. Do not edit.",
        " * This file is generated from package_config.json for offline Nix builds.",
        " */",
        "@Keep",
        "public final class GeneratedPluginRegistrant {",
        '  private static final String TAG = "GeneratedPluginRegistrant";',
        "",
        "  public static void registerWith(@NonNull FlutterEngine flutterEngine) {",
    ]

    for plugin in sorted(registrant_plugins, key=lambda item: item["name"]):
        fqcn = f'{plugin["package"]}.{plugin["plugin_class"]}'
        lines.extend(
            [
                "    try {",
                f"      flutterEngine.getPlugins().add(new {fqcn}());",
                "    } catch (Exception e) {",
                f'      Log.e(TAG, "Error registering plugin {plugin["name"]}, {fqcn}", e);',
                "    }",
            ]
        )

    lines.extend(
        [
            "  }",
            "}",
            "",
        ]
    )
    ANDROID_REGISTRANT.write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    main()
