"""Platform configuration data for Emscripten toolchain.

This module contains all platform-specific configuration data.
"""

# Common configuration values
_COMMON_UNIX_ARCHIVE = "tar.xz"
_COMMON_UNIX_BIN_EXT = ""
_COMMON_ARCH_X64 = ["x86_64", "amd64"]
_COMMON_ARCH_ARM64 = ["aarch64", "arm64"]

# Platform family base configurations
# Structure aligned with _create_platform_config output
_PLATFORM_FAMILIES = {
    "linux": {
        "os": {
            "constraint": "linux",
            "names": ["linux"],
        },
        "url": {
            "os": "linux",
        },
        "archive": {
            "type": _COMMON_UNIX_ARCHIVE,
            "bin_extension": _COMMON_UNIX_BIN_EXT,
        },
    },
    "mac": {
        "os": {
            "constraint": "macos",
            "names": ["mac", "macos", "darwin"],
        },
        "url": {
            "os": "mac",
        },
        "archive": {
            "type": _COMMON_UNIX_ARCHIVE,
            "bin_extension": _COMMON_UNIX_BIN_EXT,
        },
    },
    "win": {
        "os": {
            "constraint": "windows",
            "names": ["windows", "win"],
        },
        "url": {
            "os": "win",
        },
        "archive": {
            "type": "zip",
            "bin_extension": ".exe",
        },
    },
}

def _create_platform_config(family, cpu, arch_names, suffix = "", sha_suffix = None, optional = False):
    """Create a platform configuration by merging family defaults with specific values.

    Args:
        family: Platform family name (linux, mac, win)
        cpu: CPU architecture (x86_64, arm64)
        arch_names: List of possible architecture names from ctx.os.arch
        suffix: URL suffix for this variant (e.g., "-arm64")
        sha_suffix: Suffix for SHA attribute name (defaults to suffix without hyphen)
        optional: Whether this platform is optional for some versions

    Returns:
        Complete platform configuration dictionary
    """
    if sha_suffix == None:
        sha_suffix = suffix.replace("-", "_")

    base = _PLATFORM_FAMILIES[family]
    return {
        "os": {
            "constraint": base["os"]["constraint"],
            "names": base["os"]["names"],
        },
        "cpu": {
            "constraint": cpu,
            "names": arch_names,
        },
        "url": {
            "os": base["url"]["os"],
            "suffix": suffix,
        },
        "archive": {
            "type": base["archive"]["type"],
            "bin_extension": base["archive"]["bin_extension"],
        },
        "sha_attr": "sha_{}{}".format(family, sha_suffix),
        "optional": optional,
    }

# Platform configuration structure - all platform-specific metadata in one place
PLATFORM_CONFIGS = {
    "linux": _create_platform_config("linux", "x86_64", _COMMON_ARCH_X64),
    "linux_arm64": _create_platform_config("linux", "arm64", _COMMON_ARCH_ARM64, "-arm64", optional = True),
    "mac": _create_platform_config("mac", "x86_64", _COMMON_ARCH_X64),
    "mac_arm64": _create_platform_config("mac", "arm64", _COMMON_ARCH_ARM64, "-arm64"),
    "win": _create_platform_config("win", "x86_64", _COMMON_ARCH_X64),
}

# All supported platform names
ALL_PLATFORMS = list(PLATFORM_CONFIGS.keys())
