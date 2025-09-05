# Bazel Toolchain Modernization

## Problem Statement

The emsdk project required the deprecated Bazel flag `--incompatible_enable_cc_toolchain_resolution` to work correctly. This flag was introduced to transition from legacy toolchain resolution to modern toolchain resolution and is now deprecated.

## Root Cause Analysis

The issue was caused by the use of both **legacy** and **modern** toolchain definitions:

1. **Legacy approach**: `cc_toolchain_suite` with manual CPU/compiler mappings
2. **Modern approach**: `toolchain()` rules with platform constraints

### Why the flag was needed

- Bazel's default behavior was to use `cc_toolchain_suite` when both were present
- The `--incompatible_enable_cc_toolchain_resolution` flag forced Bazel to ignore `cc_toolchain_suite` and use modern `toolchain()` resolution
- This flag is deprecated because the legacy approach is being phased out

## Solution Implemented

### 1. Removed Legacy Toolchain Suite

**File**: `bazel/remote_emscripten_repository.bzl`

**Removed**:
```starlark
native.cc_toolchain_suite(
    name = "everything-" + name,
    toolchains = {
        "wasm": cc_wasm_target,
        "wasm|emscripten": cc_wasm_target,
    },
)
```

**Kept**: Modern `toolchain()` rules that were already properly defined:
```starlark
native.toolchain(
    name = "cc-toolchain-wasm-" + name,
    target_compatible_with = ["@platforms//cpu:wasm32"],
    exec_compatible_with = exec_compatible_with,
    toolchain = cc_wasm_target,
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
```

### 2. Removed Deprecated Flag

**Updated files**:
- `bazel/.bazelrc`
- `bazel/bazelrc`
- `bazel/test_external/.bazelrc`
- `bazel/test_secondary_lto_cache/.bazelrc`

**Removed**: `build --incompatible_enable_cc_toolchain_resolution`

### 3. Updated Documentation

**File**: `bazel/README.md`

**Removed**: Instructions to add the deprecated flag to user's `.bazelrc`

## How Modern Toolchain Resolution Works

### Automatic Selection

Bazel now automatically selects the correct toolchain based on:

1. **Target platform**: `target_compatible_with = ["@platforms//cpu:wasm32"]`
2. **Execution platform**: `exec_compatible_with = [platform_constraints]`
3. **Toolchain type**: `@bazel_tools//tools/cpp:toolchain_type`

### Platform-Specific Toolchains

The project defines toolchains for different host platforms:

- Linux x86_64: `cc-toolchain-wasm-emscripten_linux`
- Linux ARM64: `cc-toolchain-wasm-emscripten_linux_arm64`
- macOS x86_64: `cc-toolchain-wasm-emscripten_mac`
- macOS ARM64: `cc-toolchain-wasm-emscripten_mac_arm64`
- Windows x86_64: `cc-toolchain-wasm-emscripten_win`

### Registration

Toolchains are automatically registered by the `emscripten_deps` module extension in `emscripten_deps.bzl`. The extension dynamically registers toolchains based on the available Emscripten releases for each platform:

```starlark
# In emscripten_deps.bzl - automatically registers toolchains
return ctx.extension_metadata(
    root_module_direct_deps = [],
    root_module_direct_dev_deps = [],
    toolchains_registered = toolchains_to_register,
)
```

This approach provides better bzlmod compliance by:
- **Encapsulating toolchain management**: Everything related to Emscripten toolchains is handled in one module extension
- **Dynamic registration**: Only registers toolchains for platforms that have available releases
- **Reduced boilerplate**: No manual `register_toolchains()` calls needed in MODULE.bazel

## Long-Term Strategy

### 1. Maintained Compatibility

- **No breaking changes** for users
- Existing `wasm_cc_binary` rules continue to work
- Platform-based toolchain selection is now automatic

### 2. Future-Proof Architecture

- **Modern Bazel patterns**: Uses current best practices for toolchain definition
- **Platform constraints**: Proper use of Bazel's platform/constraint system
- **Bzlmod support**: Fully integrated with MODULE.bazel using module extensions
- **Automatic toolchain registration**: Toolchains are registered dynamically by module extensions

### 3. Simplified User Experience

- **No manual flag management**: Users no longer need to add deprecated flags
- **Automatic toolchain selection**: Bazel handles cross-compilation automatically
- **Clear documentation**: Updated README removes confusing legacy instructions

## Migration Benefits

1. **Eliminates deprecated flag dependency**
2. **Simplifies user configuration**
3. **Improves maintainability**
4. **Aligns with Bazel best practices**
5. **Prepares for future Bazel versions**

## Verification

To verify the changes work correctly:

1. **Build without the flag**: `bazel build //hello-world:hello-world-wasm`
2. **Cross-platform builds**: Should work on Linux, macOS, and Windows
3. **Toolchain selection**: Bazel should automatically select the correct toolchain based on host platform

## Conclusion

This modernization removes the dependency on a deprecated Bazel flag while maintaining full functionality. The project now uses modern Bazel toolchain resolution patterns that will be supported long-term.