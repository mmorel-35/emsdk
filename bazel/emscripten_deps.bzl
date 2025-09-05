"""
Utility functions for Emscripten repository management.

This module contains helper functions that are used by the emscripten_toolchain
module extension. The emscripten_deps extension itself is deprecated.
"""

def emscripten_repo_name(name):
    """Helper function to generate emscripten repository names.
    
    Args:
        name: Platform name (e.g., "linux", "mac_arm64")
        
    Returns:
        Repository name string (e.g., "emscripten_bin_linux")
    """
    return "emscripten_bin_{}".format(name)

# Deprecated extension - kept for backward compatibility but will fail if used
def _emscripten_deps_impl(ctx):
    fail("emscripten_deps extension is deprecated. Use emscripten_toolchain extension instead. See TOOLCHAIN_MODERNIZATION.md for migration instructions.")

emscripten_deps = module_extension(
    tag_classes = {},
    implementation = _emscripten_deps_impl,
)
