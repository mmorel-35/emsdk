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
```

The last version in the list (3.13) is set as the default. Users can select a different version by setting it in their project's `.bazelrc`:

```
build --python_version=3.11
```

Or by configuring their own Python toolchain in their `MODULE.bazel`.

## Local Builds

When building locally outside of Bazel's managed environment, the shell scripts will automatically search for a suitable Python version in this order:
1. python3.13
2. python3.12
3. python3.11
4. python3.10
5. python3 (validated to be >= 3.10)

If no suitable Python version is found, the build will fail with a clear error message.
