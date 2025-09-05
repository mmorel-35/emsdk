"""
DEPRECATED: This module extension is no longer used.

Use the consolidated emscripten_toolchain extension instead:

```starlark
emscripten_toolchain = use_extension("//:emscripten_toolchain.bzl", "emscripten_toolchain")
emscripten_toolchain.config(version = "latest")  # Optional version configuration
emscripten_toolchain.platform(name = "linux")   # Optional platform selection
```

The emscripten_toolchain extension handles:
1. Emscripten binary downloads (emscripten_bin_* repositories)
2. Toolchain registration
3. Platform-specific optimization to reduce unnecessary downloads
"""

def emscripten_repo_name(name):
    """Helper function to generate emscripten repository names."""
    return "emscripten_bin_{}".format(name)

# Legacy extension kept for backward compatibility
def _emscripten_deps_impl(ctx):
    fail("emscripten_deps extension is deprecated. Use emscripten_toolchain extension instead.")

emscripten_deps = module_extension(
    tag_classes = {},
    implementation = _emscripten_deps_impl,
)
