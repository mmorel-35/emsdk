"""Legacy API for Emscripten toolchain extension (backward compatibility).

Deprecated: New code should use the unified API from extensions.bzl instead:
    emscripten = use_extension("//:extensions.bzl", "emscripten")
    emscripten.toolchain(version = "3.1.51", platforms = ["mac_arm64"])

This file maintains the old API for backward compatibility.
"""

load("//private/extensions:legacy_extension.bzl", _emscripten_toolchain_extension = "emscripten_toolchain_extension")

# Export the legacy extension for backward compatibility
emscripten_toolchain = _emscripten_toolchain_extension
