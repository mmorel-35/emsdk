"""Module extension for coordinating Emscripten platform selection and toolchain registration."""

load(":emscripten_deps.bzl", "emscripten_repo_name")
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
    
    This extension coordinates platform selection across:
    1. Emscripten binary downloads (emscripten_bin_* repositories)
    2. NPM dependency processing (emscripten_npm_* repositories) 
    3. Toolchain registration
    
    Only downloads and processes platforms that are explicitly requested,
    reducing bandwidth and storage requirements.
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
    
    # Collect all platform configurations from modules
    enabled_platforms = []
    for mod in ctx.modules:
        for config in mod.tags.platform:
            if config.name not in enabled_platforms:
                enabled_platforms.append(config.name)
    
    # If no platforms specified, enable all available platforms (backward compatibility)
    if not enabled_platforms:
        enabled_platforms = ["linux", "linux_arm64", "mac", "mac_arm64", "win"]
    
    # Create emscripten_bin repositories only for enabled platforms
    emscripten_url = "https://storage.googleapis.com/webassembly/emscripten-releases-builds/{}/{}/wasm-binaries{}.{}"
    
    # Repository names that will be created
    repo_names = []
    
    for platform in enabled_platforms:
        repo_name = emscripten_repo_name(platform)
        repo_names.append(repo_name)
        
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
        toolchains_registered = toolchains_to_register,
    )

emscripten_toolchain = module_extension(
    tag_classes = {
        "platform": tag_class(
            attrs = {
                "name": attr.string(
                    doc = "Platform name to enable toolchain for",
                    values = ["linux", "linux_arm64", "mac", "mac_arm64", "win"],
                    mandatory = True,
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
)