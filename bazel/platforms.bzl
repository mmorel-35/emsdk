"""Centralized platform definitions and utilities for Emscripten toolchain."""

# Platform configuration structure - all platform-specific metadata in one place
# This makes it easy to add new platforms or modify existing ones
PLATFORM_CONFIGS = {
    "linux": {
        "os": "linux",
        "cpu": "x86_64",
        "os_names": ["linux"],  # Possible values from ctx.os.name
        "arch_names": ["x86_64", "amd64"],  # Possible values from ctx.os.arch
        "url_os": "linux",
        "url_suffix": "",
        "archive_type": "tar.xz",
        "bin_extension": "",
        "sha_attr": "sha_linux",
    },
    "linux_arm64": {
        "os": "linux",
        "cpu": "arm64",
        "os_names": ["linux"],
        "arch_names": ["aarch64", "arm64"],
        "url_os": "linux",
        "url_suffix": "-arm64",
        "archive_type": "tar.xz",
        "bin_extension": "",
        "sha_attr": "sha_linux_arm64",
        "optional": True,  # Not all versions have this platform
    },
    "mac": {
        "os": "macos",
        "cpu": "x86_64",
        "os_names": ["mac", "macos", "darwin"],
        "arch_names": ["x86_64", "amd64"],
        "url_os": "mac",
        "url_suffix": "",
        "archive_type": "tar.xz",
        "bin_extension": "",
        "sha_attr": "sha_mac",
    },
    "mac_arm64": {
        "os": "macos",
        "cpu": "arm64",
        "os_names": ["mac", "macos", "darwin"],
        "arch_names": ["aarch64", "arm64"],
        "url_os": "mac",
        "url_suffix": "-arm64",
        "archive_type": "tar.xz",
        "bin_extension": "",
        "sha_attr": "sha_mac_arm64",
    },
    "win": {
        "os": "windows",
        "cpu": "x86_64",
        "os_names": ["windows", "win"],
        "arch_names": ["x86_64", "amd64"],
        "url_os": "win",
        "url_suffix": "",
        "archive_type": "zip",
        "bin_extension": ".exe",
        "sha_attr": "sha_win",
    },
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
            os_constraint, cpu_constraint, ", ".join(supported)))
    
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
            platform_name, ", ".join(ALL_PLATFORMS)))
    
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
            platform_name, ", ".join(ALL_PLATFORMS)))
    
    return PLATFORM_CONFIGS[platform_name]
