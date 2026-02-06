"""Centralized platform definitions and utilities for Emscripten toolchain."""

# Common configuration values to reduce duplication (DRY principle)
_COMMON_UNIX_ARCHIVE = "tar.xz"
_COMMON_UNIX_BIN_EXT = ""
_COMMON_ARCH_X64 = ["x86_64", "amd64"]
_COMMON_ARCH_ARM64 = ["aarch64", "arm64"]

# Platform family base configurations
_PLATFORM_FAMILIES = {
    "linux": {
        "os": "linux",
        "os_names": ["linux"],
        "url": {
            "os": "linux",
        },
        "archive": {
            "type": _COMMON_UNIX_ARCHIVE,
            "bin_extension": _COMMON_UNIX_BIN_EXT,
        },
    },
    "mac": {
        "os": "macos",
        "os_names": ["mac", "macos", "darwin"],
        "url": {
            "os": "mac",
        },
        "archive": {
            "type": _COMMON_UNIX_ARCHIVE,
            "bin_extension": _COMMON_UNIX_BIN_EXT,
        },
    },
    "win": {
        "os": "windows",
        "os_names": ["windows", "win"],
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
        "os": base["os"],
        "cpu": cpu,
        "os_names": base["os_names"],
        "arch_names": arch_names,
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
# Using DRY principle with helper function to reduce duplication
PLATFORM_CONFIGS = {
    "linux": _create_platform_config("linux", "x86_64", _COMMON_ARCH_X64),
    "linux_arm64": _create_platform_config("linux", "arm64", _COMMON_ARCH_ARM64, "-arm64", optional = True),
    "mac": _create_platform_config("mac", "x86_64", _COMMON_ARCH_X64),
    "mac_arm64": _create_platform_config("mac", "arm64", _COMMON_ARCH_ARM64, "-arm64"),
    "win": _create_platform_config("win", "x86_64", _COMMON_ARCH_X64),
}

# Build platform mappings from configs
def _build_platform_mappings():
    """Build platform mappings from configuration."""
    mappings = {}
    for name, config in PLATFORM_CONFIGS.items():
        mappings[(config["os"], config["cpu"])] = name
    return mappings

# Standard platform mappings between Bazel constraints and internal platform names
PLATFORM_MAPPINGS = _build_platform_mappings()

# Reverse mapping for lookups
INTERNAL_TO_CONSTRAINTS = {v: k for k, v in PLATFORM_MAPPINGS.items()}

# All supported platform names
ALL_PLATFORMS = list(PLATFORM_CONFIGS.keys())

def constraint_to_platform_name(constraints):
    """Convert platform constraints to internal platform name.

    Args:
        constraints: List of Bazel platform constraint strings

    Returns:
        Internal platform name string

    Raises:
        fail() if constraints are invalid or unsupported
    """
    os_constraint = None
    cpu_constraint = None

    for constraint in constraints:
        if constraint.startswith("@platforms//os:"):
            os_constraint = constraint[len("@platforms//os:"):]
        elif constraint.startswith("@platforms//cpu:"):
            cpu_constraint = constraint[len("@platforms//cpu:"):]

    if not os_constraint or not cpu_constraint:
        fail("Platform must specify both OS and CPU constraints. Got: {}".format(constraints))

    platform_key = (os_constraint, cpu_constraint)
    if platform_key not in PLATFORM_MAPPINGS:
        supported = ["{}/{}".format(os, cpu) for os, cpu in PLATFORM_MAPPINGS.keys()]
        fail("Unsupported platform combination: {}/{}. Supported: {}".format(
            os_constraint,
            cpu_constraint,
            ", ".join(supported),
        ))

    return PLATFORM_MAPPINGS[platform_key]

def platform_name_to_constraints(platform_name):
    """Convert internal platform name to Bazel constraints.

    Args:
        platform_name: Internal platform name

    Returns:
        List of constraint strings

    Raises:
        fail() if platform_name is not supported
    """
    if platform_name not in PLATFORM_CONFIGS:
        fail("Unknown platform name: {}. Supported: {}".format(
            platform_name,
            ", ".join(ALL_PLATFORMS),
        ))

    config = PLATFORM_CONFIGS[platform_name]
    return [
        "@platforms//os:{}".format(config["os"]),
        "@platforms//cpu:{}".format(config["cpu"]),
    ]

def detect_host_platform(ctx):
    """Detect the host platform based on Bazel's os and arch information.

    Args:
        ctx: Repository or module extension context

    Returns:
        Internal platform name for the detected host
    """

    # Normalize OS and architecture names
    os_name = ctx.os.name.lower()
    arch_name = ctx.os.arch.lower()

    # Find matching platform by checking os_names and arch_names
    for platform_name, config in PLATFORM_CONFIGS.items():
        # Check if OS matches any of the known OS names for this platform
        os_match = False
        for name in config["os_names"]:
            if os_name.startswith(name):
                os_match = True
                break

        # Check if architecture matches any of the known arch names for this platform
        arch_match = arch_name in config["arch_names"]

        if os_match and arch_match:
            return platform_name

    # Fallback to linux x86_64 for unknown platforms
    return "linux"

def get_platform_config(platform_name):
    """Get the configuration for a specific platform.

    Args:
        platform_name: Internal platform name

    Returns:
        Dictionary with platform configuration

    Raises:
        fail() if platform_name is not supported
    """
    if platform_name not in PLATFORM_CONFIGS:
        fail("Unknown platform name: {}. Supported: {}".format(
            platform_name,
            ", ".join(ALL_PLATFORMS),
        ))

    return PLATFORM_CONFIGS[platform_name]
