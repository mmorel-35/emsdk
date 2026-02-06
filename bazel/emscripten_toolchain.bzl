"""Module extension for coordinating Emscripten platform selection and toolchain registration."""

load(":emscripten_deps.bzl", "emscripten_repo_name")
load(":platforms.bzl", "constraint_to_platform_name", "detect_host_platform", "ALL_PLATFORMS")
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
            if hasattr(config, 'constraints') and config.constraints:
                # New constraint-based platform specification
                platform_name = constraint_to_platform_name(config.constraints)
                if platform_name not in enabled_platforms:
                    enabled_platforms.append(platform_name)
            elif hasattr(config, 'name') and config.name:
                # Legacy name-based platform specification (for backward compatibility)
                if config.name not in ALL_PLATFORMS:
                    fail("Unknown platform name: {}. Supported: {}".format(
                        config.name, ", ".join(ALL_PLATFORMS)))
                if config.name not in enabled_platforms:
                    enabled_platforms.append(config.name)
    
    # Create emscripten_bin repositories - always create all repos for consistent use_repo
    # But only download binaries for enabled platforms
    emscripten_url = "https://storage.googleapis.com/webassembly/emscripten-releases-builds/{}/{}/wasm-binaries{}.{}"
    
    # Repository names that will be created and exposed
    repo_names = []
    
    # Always create all platform repositories for consistent API
    for platform in ALL_PLATFORMS:
        repo_name = emscripten_repo_name(platform)
        repo_names.append(repo_name)
        
        # Only download binaries for enabled platforms
        if platform not in enabled_platforms:
            _empty_repository(name = repo_name)
            continue
        
        if platform == "linux":
            remote_emscripten_repository(
                name = repo_name,
                bin_extension = "",
                sha256 = revision.sha_linux,
                strip_prefix = "install",
                type = "tar.xz",
                url = emscripten_url.format("linux", revision.hash, "", "tar.xz"),
            )
        elif platform == "linux_arm64":
            # Not all versions have a linux/arm64 release
            if hasattr(revision, "sha_linux_arm64"):
                remote_emscripten_repository(
                    name = repo_name,
                    bin_extension = "",
                    sha256 = revision.sha_linux_arm64,
                    strip_prefix = "install",
                    type = "tar.xz",
                    url = emscripten_url.format("linux", revision.hash, "-arm64", "tar.xz"),
                )
            else:
                _empty_repository(name = repo_name)
        elif platform == "mac":
            remote_emscripten_repository(
                name = repo_name,
                bin_extension = "",
                sha256 = revision.sha_mac,
                strip_prefix = "install",
                type = "tar.xz",
                url = emscripten_url.format("mac", revision.hash, "", "tar.xz"),
            )
        elif platform == "mac_arm64":
            remote_emscripten_repository(
                name = repo_name,
                bin_extension = "",
                sha256 = revision.sha_mac_arm64,
                strip_prefix = "install",
                type = "tar.xz",
                url = emscripten_url.format("mac", revision.hash, "-arm64", "tar.xz"),
            )
        elif platform == "win":
            remote_emscripten_repository(
                name = repo_name,
                bin_extension = ".exe",
                sha256 = revision.sha_win,
                strip_prefix = "install",
                type = "zip",
                url = emscripten_url.format("win", revision.hash, "", "zip"),
            )
    
    # Build list of toolchains to register based on enabled platforms
    toolchains_to_register = []
    for platform in enabled_platforms:
        toolchain_label = "//emscripten_toolchain:cc-toolchain-wasm-emscripten_{}".format(platform)
        toolchains_to_register.append(toolchain_label)
    
    return ctx.extension_metadata(
        root_module_direct_deps = repo_names,
        root_module_direct_dev_deps = [],
    )

emscripten_toolchain = module_extension(
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
