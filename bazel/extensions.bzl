"""Unified module extension for Emscripten toolchain configuration.

This provides a clean, modern API similar to rules_rust and other state-of-the-art toolchains.
All configuration is done through a single toolchain() tag class.
"""

load(":emscripten_deps.bzl", "emscripten_repo_name")
load(":platforms.bzl", "ALL_PLATFORMS", "constraint_to_platform_name", "detect_host_platform", "get_platform_config")
load(":remote_emscripten_repository.bzl", "remote_emscripten_repository")
load(":revisions.bzl", "EMSCRIPTEN_TAGS")

def _parse_version(v):
    return [int(u) for u in v.split(".")]

def _empty_repository_impl(ctx):
    ctx.file("MODULE.bazel", """module(name = "{}")""".format(ctx.name))
    ctx.file("BUILD.bazel", "")

_empty_repository = repository_rule(
    implementation = _empty_repository_impl,
)

def _create_platform_repository(platform, repo_name, revision, emscripten_url):
    """Create a repository for a specific platform using its configuration.

    Args:
        platform: Platform name (e.g., "linux", "mac_arm64")
        repo_name: Name for the repository
        revision: Emscripten revision object with SHA attributes
        emscripten_url: URL template for downloading binaries
    """
    config = get_platform_config(platform)

    # Check if this is an optional platform and SHA is available
    if config.get("optional", False):
        if not hasattr(revision, config["sha_attr"]):
            _empty_repository(name = repo_name)
            return

    # Get the SHA256 hash for this platform
    sha256 = getattr(revision, config["sha_attr"])

    # Build the download URL using platform configuration
    url = emscripten_url.format(
        config["url"]["os"],
        revision.hash,
        config["url"]["suffix"],
        config["archive"]["type"],
    )

    # Create the repository with platform-specific settings
    remote_emscripten_repository(
        name = repo_name,
        bin_extension = config["archive"]["bin_extension"],
        sha256 = sha256,
        strip_prefix = "install",
        type = config["archive"]["type"],
        url = url,
    )



def _emscripten_impl(ctx):
    """Implementation of the unified emscripten module extension.

    This extension provides a clean, modern interface for Emscripten toolchain setup:
    1. Auto-detects host platform and downloads only necessary binaries
    2. Single toolchain() tag class for all configuration
    3. Automatically handles NPM dependencies for enabled platforms
    4. Registers toolchains without manual configuration
    5. Exposes all created repositories automatically

    Example usage:
        emscripten = use_extension("//:extensions.bzl", "emscripten")
        
        # Simple: auto-detect host platform
        emscripten.toolchain()
        
        # With version:
        emscripten.toolchain(version = "3.1.51")
        
        # With explicit platforms (legacy names):
        emscripten.toolchain(
            version = "3.1.51",
            platforms = ["mac_arm64", "linux"],
        )
        
        # With platform constraints (modern, dict mapping):
        emscripten.toolchain(
            version = "3.1.51",
            platform_to_constraints = {
                "mac_arm64": ["@platforms//os:macos", "@platforms//cpu:arm64"],
                "linux": ["@platforms//os:linux", "@platforms//cpu:x86_64"],
            },
        )
        
        # Or use auto-detected names with constraints:
        emscripten.toolchain(
            constraints = ["@platforms//os:macos", "@platforms//cpu:arm64"],
        )
    """

    # Collect configuration from toolchain tags
    version = None
    enabled_platforms = []

    for mod in ctx.modules:
        for toolchain_tag in mod.tags.toolchain:
            # Process version (only one allowed across all tags)
            if toolchain_tag.version:
                if version != None and version != toolchain_tag.version:
                    fail("Multiple different emscripten versions specified: {} and {}".format(
                        version,
                        toolchain_tag.version,
                    ))
                version = toolchain_tag.version

            # Process platform_to_constraints dict (modern, explicit mapping)
            if toolchain_tag.platform_to_constraints:
                for platform_name, constraints in toolchain_tag.platform_to_constraints.items():
                    # Validate that the platform name is known
                    if platform_name not in ALL_PLATFORMS:
                        fail("Unknown platform name '{}' in platform_to_constraints. Supported: {}".format(
                            platform_name,
                            ", ".join(ALL_PLATFORMS),
                        ))
                    # TODO: Could validate constraints match the platform, but that's complex
                    if platform_name not in enabled_platforms:
                        enabled_platforms.append(platform_name)

            # Process constraint-based platform specification (auto-detect platform name)
            if toolchain_tag.constraints:
                platform_name = constraint_to_platform_name(toolchain_tag.constraints)
                if platform_name not in enabled_platforms:
                    enabled_platforms.append(platform_name)

            # Process legacy platform names
            if toolchain_tag.platforms:
                for platform_name in toolchain_tag.platforms:
                    if platform_name not in ALL_PLATFORMS:
                        fail("Unknown platform name: {}. Supported: {}".format(
                            platform_name,
                            ", ".join(ALL_PLATFORMS),
                        ))
                    if platform_name not in enabled_platforms:
                        enabled_platforms.append(platform_name)

    # Default version to latest if not specified
    if version == None:
        version = "latest"

    if version == "latest":
        version = reversed(sorted(EMSCRIPTEN_TAGS.keys(), key = _parse_version))[0]

    revision = EMSCRIPTEN_TAGS[version]

    # Auto-detect host platform if no platforms were explicitly specified
    if not enabled_platforms:
        host_platform = detect_host_platform(ctx)
        enabled_platforms = [host_platform]

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
        _create_platform_repository(platform, repo_name, revision, emscripten_url)

    return ctx.extension_metadata(
        root_module_direct_deps = repo_names,
        root_module_direct_dev_deps = [],
    )

emscripten = module_extension(
    tag_classes = {
        "toolchain": tag_class(
            attrs = {
                "version": attr.string(
                    doc = "Emscripten version to use. Defaults to 'latest'. Available: {}".format(", ".join(sorted(EMSCRIPTEN_TAGS.keys()))),
                ),
                "platforms": attr.string_list(
                    doc = """List of platform names to enable (legacy). Example: ["mac_arm64", "linux"].
                    Auto-detected if no platform specification is provided.
                    Supported: {}""".format(", ".join(ALL_PLATFORMS)),
                ),
                "constraints": attr.string_list(
                    doc = """Platform constraints to enable (modern, auto-detect platform name). 
                    Must include both OS and CPU constraints.
                    Example: ["@platforms//os:macos", "@platforms//cpu:arm64"].
                    The platform name will be auto-detected from constraints.""",
                ),
                "platform_to_constraints": attr.string_list_dict(
                    doc = """Explicit mapping of platform names to constraints (most flexible).
                    Example: {"mac_arm64": ["@platforms//os:macos", "@platforms//cpu:arm64"]}.
                    This allows specifying exact platform names with their constraints.""",
                ),
            },
        ),
    },
    implementation = _emscripten_impl,
    os_dependent = True,
    arch_dependent = True,
)
