"""Public API for platform utilities.

This module provides utility functions and constants for working with
Emscripten platforms, including platform detection and configuration.

Exports:
    - ALL_PLATFORMS: List of all supported platform names
    - PLATFORM_CONFIGS: Configuration data for all platforms
    - PLATFORM_MAPPINGS: Mapping between platform names and constraints
    - detect_host_platform(): Auto-detect the current host platform
    - get_platform_config(): Get configuration for a specific platform
    - get_platform_constraints(): Get Bazel constraints for a platform
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
