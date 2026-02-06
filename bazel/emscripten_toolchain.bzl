"""Emscripten toolchain extension with platform() and config() tags.

This module provides the emscripten_toolchain extension with separate platform()
and config() tags for configuring the Emscripten toolchain.

Alternative: For a more concise API, see extensions.bzl which provides a unified
toolchain() tag that combines version and platform configuration.

Example:
    emscripten_toolchain = use_extension("//:emscripten_toolchain.bzl", "emscripten_toolchain")
    emscripten_toolchain.config(version = "3.1.51")
    emscripten_toolchain.platform(name = "mac_arm64")
"""

load("//private/extensions:legacy_extension.bzl", _emscripten_toolchain_extension = "emscripten_toolchain_extension")

# Export the legacy extension for backward compatibility
emscripten_toolchain = _emscripten_toolchain_extension
