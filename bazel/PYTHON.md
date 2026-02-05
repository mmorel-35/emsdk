# Python Version Requirements

Emscripten requires Python 3.10 or higher due to the use of structural pattern matching (`match` statement) in its codebase.

## Supported Python Versions

The following Python versions are registered as toolchains in `MODULE.bazel`:

- Python 3.10 (minimum required)
- Python 3.11
- Python 3.12
- Python 3.13 (default)

## Configuration

Multiple Python toolchains are registered using a list-based approach (similar to grpc):

```starlark
PYTHON_VERSIONS = [
    "3.10",
    "3.11",
    "3.12",
    "3.13",
]

python = use_extension("@rules_python//python/extensions:python.bzl", "python")

[
    python.toolchain(
        is_default = python_version == PYTHON_VERSIONS[-1],
        python_version = python_version,
    )
    for python_version in PYTHON_VERSIONS
]

# Expose Python runtime for use in toolchain
use_repo(python, "python_3_13")
```

The last version in the list (3.13) is set as the default. Users can select a different version by setting it in their project's `.bazelrc`:

```
build --python_version=3.11
```

Or by configuring their own Python toolchain in their `MODULE.bazel`.

## How It Works

Bazel's registered Python toolchains are hermetically available during build execution. The emscripten shell scripts (`emcc.sh`, `emar.sh`, `emcc_link.sh`) simply call `python3` directly, and Bazel ensures the correct version is available in the execution environment.

This approach:
- Avoids searching PATH for Python
- Uses Bazel's hermetic toolchain resolution
- Ensures consistent Python version across all platforms
- Simplifies the shell scripts (no version detection needed)
