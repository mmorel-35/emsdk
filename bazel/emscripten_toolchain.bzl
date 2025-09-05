"""Module extension for registering Emscripten toolchains."""

def _emscripten_toolchain_impl(ctx):
    """Implementation of the emscripten_toolchain module extension.
    
    This extension handles the registration of Emscripten toolchains,
    providing better encapsulation and dynamic configuration capabilities.
    """
    
    # Collect all toolchain configurations from modules
    enabled_platforms = []
    for mod in ctx.modules:
        for config in mod.tags.platform:
            if config.name not in enabled_platforms:
                enabled_platforms.append(config.name)
    
    # If no platforms specified, register all available toolchains
    if not enabled_platforms:
        enabled_platforms = ["linux", "linux_arm64", "mac", "mac_arm64", "win"]
    
    # Build list of toolchains to register based on enabled platforms
    toolchains_to_register = []
    
    for platform in enabled_platforms:
        toolchain_label = "//emscripten_toolchain:cc-toolchain-wasm-emscripten_{}".format(platform)
        toolchains_to_register.append(toolchain_label)
    
    return ctx.extension_metadata(
        root_module_direct_deps = [],
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
    },
    implementation = _emscripten_toolchain_impl,
)