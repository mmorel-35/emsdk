"""Platform auto-detection logic for Emscripten toolchain.

This module handles automatic detection of the host platform based on Bazel's
runtime environment information.
"""

load(":config.bzl", "PLATFORM_CONFIGS")

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
        for name in config["os"]["names"]:
            if os_name.startswith(name):
                os_match = True
                break

        # Check if architecture matches any of the known arch names for this platform
        arch_match = arch_name in config["cpu"]["names"]

        if os_match and arch_match:
            return platform_name

    # Fallback to linux x86_64 for unknown platforms
    return "linux"
