"""Platform utility functions for Emscripten toolchain.

This module provides utility functions for working with platform configurations,
including constraint conversions and lookups.
"""

load(":config.bzl", "ALL_PLATFORMS", "PLATFORM_CONFIGS")

# Build platform mappings from configs
def _build_platform_mappings():
    """Build platform mappings from configuration."""
    mappings = {}
    for name, config in PLATFORM_CONFIGS.items():
        mappings[(config["os"]["constraint"], config["cpu"]["constraint"])] = name
    return mappings

# Standard platform mappings between Bazel constraints and internal platform names
PLATFORM_MAPPINGS = _build_platform_mappings()

# Reverse mapping for lookups
INTERNAL_TO_CONSTRAINTS = {v: k for k, v in PLATFORM_MAPPINGS.items()}

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

def get_platform_constraints(platform_name):
    """Get Bazel platform constraints for a platform name.

    Args:
        platform_name: Internal platform name

    Returns:
        List of constraint strings

    Raises:
        fail() if platform_name is not supported
    """
    config = get_platform_config(platform_name)
    return [
        "@platforms//os:{}".format(config["os"]["constraint"]),
        "@platforms//cpu:{}".format(config["cpu"]["constraint"]),
    ]

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

    Alias for get_platform_constraints for backward compatibility.

    Args:
        platform_name: Internal platform name

    Returns:
        List of constraint strings

    Raises:
        fail() if platform_name is not supported
    """
    return get_platform_constraints(platform_name)
