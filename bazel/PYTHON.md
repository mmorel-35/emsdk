# Python Version Requirements

Emscripten requires Python 3.10 or higher due to the use of structural pattern matching (`match` statement) in its codebase.

## Supported Python Versions

- Python 3.10 (minimum)
- Python 3.11 (recommended default)
- Python 3.12
- Python 3.13

## Configuration

The default Python version is configured in `MODULE.bazel`:

```starlark
python.toolchain(
    python_version = "3.13",
)
```

Users can override this in their own `MODULE.bazel` if they use emsdk as a dependency.

## Local Builds

When building locally outside of Bazel's managed environment, the shell scripts will automatically search for a suitable Python version in this order:
1. python3.13
2. python3.12
3. python3.11
4. python3.10
5. python3 (validated to be >= 3.10)

If no suitable Python version is found, the build will fail with a clear error message.
