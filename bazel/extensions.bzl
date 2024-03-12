load(":emscripten_deps.bzl", "emscripten_deps")

def _non_module_dependencies_impl(_ctx):
    emscripten_deps()

non_module_dependencies = module_extension(
    implementation = _non_module_dependencies_impl,
)
