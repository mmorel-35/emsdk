"""Repository factory for creating Emscripten platform repositories.

This module handles the creation of platform-specific repositories, including
both actual Emscripten binaries and empty placeholder repositories for disabled platforms.
"""

load("//:remote_emscripten_repository.bzl", "remote_emscripten_repository")
load("//private/platforms:utils.bzl", "get_platform_config")

def _empty_repository_impl(ctx):
    """Create an empty repository as a placeholder for disabled platforms."""
    ctx.file("MODULE.bazel", """module(name = "{}")""".format(ctx.name))
    ctx.file("BUILD.bazel", "")

_empty_repository = repository_rule(
    implementation = _empty_repository_impl,
)

def create_platform_repository(platform, repo_name, revision, emscripten_url):
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
