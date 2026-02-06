"""Public API for platform utilities (backward compatibility).

Deprecated: Internal implementation moved to private/platforms/.
This file re-exports public symbols for backward compatibility.

For new code, prefer using the extension APIs from extensions.bzl or emscripten_toolchain.bzl.
"""

load("//private/platforms:config.bzl", _ALL_PLATFORMS = "ALL_PLATFORMS", _PLATFORM_CONFIGS = "PLATFORM_CONFIGS")
load("//private/platforms:detection.bzl", _detect_host_platform = "detect_host_platform")
load(
    "//private/platforms:utils.bzl",
    _INTERNAL_TO_CONSTRAINTS = "INTERNAL_TO_CONSTRAINTS",
    _PLATFORM_MAPPINGS = "PLATFORM_MAPPINGS",
    _constraint_to_platform_name = "constraint_to_platform_name",
    _get_platform_config = "get_platform_config",
    _get_platform_constraints = "get_platform_constraints",
    _platform_name_to_constraints = "platform_name_to_constraints",
)

# Re-export all public symbols for backward compatibility
ALL_PLATFORMS = _ALL_PLATFORMS
PLATFORM_CONFIGS = _PLATFORM_CONFIGS
PLATFORM_MAPPINGS = _PLATFORM_MAPPINGS
INTERNAL_TO_CONSTRAINTS = _INTERNAL_TO_CONSTRAINTS
detect_host_platform = _detect_host_platform
get_platform_config = _get_platform_config
get_platform_constraints = _get_platform_constraints
constraint_to_platform_name = _constraint_to_platform_name
platform_name_to_constraints = _platform_name_to_constraints
