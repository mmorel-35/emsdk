"""Public API entry point for Emscripten toolchain module extensions.

This is the main entry point for users to configure the Emscripten toolchain.
It provides a modern, unified API similar to rules_rust and toolchains_llvm.

Example usage:
    # In MODULE.bazel
    emscripten = use_extension("//:extensions.bzl", "emscripten")
    
    # Simple: auto-detect host platform
    emscripten.toolchain()
    
    # With version:
    emscripten.toolchain(version = "3.1.51")
    
    # With explicit platforms:
    emscripten.toolchain(
        version = "3.1.51",
        platforms = ["mac_arm64", "linux"],
    )
    
    # With platform constraints (modern):
    emscripten.toolchain(
        version = "3.1.51",
        platform_to_constraints = {
            "mac_arm64": ["@platforms//os:macos", "@platforms//cpu:arm64"],
        },
    )
"""

load("//private/extensions:toolchain_extension.bzl", _emscripten_toolchain_extension = "emscripten_toolchain_extension")

# Export the unified emscripten extension as the public API
emscripten = _emscripten_toolchain_extension
