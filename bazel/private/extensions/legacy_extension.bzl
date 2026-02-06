"""Emscripten toolchain extension implementation with platform() and config() tags.

This module implements the emscripten_toolchain extension with separate
platform() and config() tags for maximum flexibility.

Alternative API: extensions.bzl provides a unified toolchain() tag that
combines version and platform configuration in a single call.
"""

load("//:emscripten_deps.bzl", "emscripten_repo_name")
load("//:revisions.bzl", "EMSCRIPTEN_TAGS")
load("//private/platforms:config.bzl", "ALL_PLATFORMS")
load("//private/platforms:detection.bzl", "detect_host_platform")
load("//private/platforms:utils.bzl", "constraint_to_platform_name")
load("//private/repositories:repository_factory.bzl", "create_platform_repository")

def _parse_version(v):
    """Parse version string into comparable list of integers."""
    return [int(u) for u in v.split(".")]

def _empty_repository_impl(ctx):
    """Create an empty repository as a placeholder for disabled platforms."""
    ctx.file("MODULE.bazel", """module(name = "{}")""".format(ctx.name))
    ctx.file("BUILD.bazel", "")

_empty_repository = repository_rule(
    implementation = _empty_repository_impl,
)

def _emscripten_toolchain_impl(ctx):
    """Implementation of the emscripten_toolchain module extension.

    This extension provides a simplified interface for Emscripten toolchain setup:
    1. Auto-detects host platform and downloads only necessary binaries
    2. Automatically handles NPM dependencies for enabled platforms
    3. Registers toolchains without manual configuration
    4. Exposes all created repositories automatically

    Users only need minimal configuration with optional additional platforms.
    """

    # Collect version configuration
    version = None
    for mod in ctx.modules:
        for config in mod.tags.config:
            if config.version and version != None:
                fail("More than one emscripten version specified!")
            version = config.version
    if version == None:
        version = "latest"

    if version == "latest":
        version = reversed(sorted(EMSCRIPTEN_TAGS.keys(), key = _parse_version))[0]

    revision = EMSCRIPTEN_TAGS[version]

    # Auto-detect host platform for minimal configuration
    host_platform = detect_host_platform(ctx)

    # Start with host platform enabled by default
    enabled_platforms = [host_platform]

    # Collect additional platform configurations from modules
    for mod in ctx.modules:
        for config in mod.tags.platform:
            if hasattr(config, "constraints") and config.constraints:
                # New constraint-based platform specification
                platform_name = constraint_to_platform_name(config.constraints)
                if platform_name not in enabled_platforms:
                    enabled_platforms.append(platform_name)
            elif hasattr(config, "name") and config.name:
                # Legacy name-based platform specification (for backward compatibility)
                if config.name not in ALL_PLATFORMS:
                    fail("Unknown platform name: {}. Supported: {}".format(
                        config.name,
                        ", ".join(ALL_PLATFORMS),
                    ))
                if config.name not in enabled_platforms:
                    enabled_platforms.append(config.name)

    # URL template for Emscripten binaries
    emscripten_url = "https://storage.googleapis.com/webassembly/emscripten-releases-builds/{}/{}/wasm-binaries{}.{}"

    # Repository names that will be created and exposed
    repo_names = []

    # Create repositories for all platforms using data-driven approach
    for platform in ALL_PLATFORMS:
        repo_name = emscripten_repo_name(platform)
        repo_names.append(repo_name)

        # Only download binaries for enabled platforms
        if platform not in enabled_platforms:
            _empty_repository(name = repo_name)
            continue

        # Use configuration-driven repository creation
        create_platform_repository(platform, repo_name, revision, emscripten_url)

    return ctx.extension_metadata(
        root_module_direct_deps = repo_names,
        root_module_direct_dev_deps = [],
    )

# Legacy extension for backward compatibility
emscripten_toolchain_extension = module_extension(
    tag_classes = {
        "platform": tag_class(
            attrs = {
                "name": attr.string(
                    doc = "Platform name to enable toolchain for (legacy). Supported: {}".format(", ".join(ALL_PLATFORMS)),
                ),
                "constraints": attr.string_list(
                    doc = "Platform constraints to enable toolchain for (recommended). Must include both OS and CPU constraints, e.g., ['@platforms//os:linux', '@platforms//cpu:x86_64']",
                ),
            },
        ),
        "config": tag_class(
            attrs = {
                "version": attr.string(
                    doc = "Version to use. 'latest' to use latest.",
                    values = ["latest"] + EMSCRIPTEN_TAGS.keys(),
                ),
            },
        ),
    },
    implementation = _emscripten_toolchain_impl,
    os_dependent = True,
    arch_dependent = True,
)
