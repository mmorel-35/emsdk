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

Toolchains are automatically registered by a dedicated `emscripten_toolchain` module extension in `emscripten_toolchain.bzl`. This provides better separation of concerns by decoupling toolchain registration from dependency management:

```starlark
# In MODULE.bazel
emscripten_toolchain = use_extension("//:emscripten_toolchain.bzl", "emscripten_toolchain")
```

The extension supports configurable platform selection:
```starlark
# Optional: Register toolchains for specific platforms only
emscripten_toolchain.platform(name = "linux")
emscripten_toolchain.platform(name = "mac")
```

This approach provides better bzlmod compliance by:
- **Separation of concerns**: Toolchain registration is separate from dependency management
- **Configurability**: Users can selectively enable toolchains for specific platforms
- **Modularity**: Toolchain configuration is self-contained in its own extension
- **Reduced coupling**: Changes to dependency management don't affect toolchain registration
- **Platform-specific optimization**: Only downloads binaries for requested platforms

## Platform-Specific Optimization

### Problem: Excessive Downloads

Previously, the system downloaded binaries for all 5 supported platforms (Linux, Linux ARM64, Mac, Mac ARM64, Windows) regardless of which platforms were actually needed. This resulted in:

- **Wasted bandwidth**: Users downloading ~500MB+ of unnecessary binaries
- **Storage overhead**: Local caches storing unused platform binaries  
- **Slower setup**: Extended download times for unused platforms
- **NPM processing**: Translating packages for all platforms regardless of usage

### Solution: Selective Platform Downloads

The `emscripten_toolchain` extension now coordinates platform selection across all components:

```starlark
# In MODULE.bazel - only download what you need
emscripten_toolchain = use_extension("//:emscripten_toolchain.bzl", "emscripten_toolchain")
emscripten_toolchain.platform(name = "linux")
emscripten_toolchain.platform(name = "mac") 
# Only Linux and Mac binaries are downloaded and processed

use_repo(emscripten_toolchain, "emscripten_bin_linux", "emscripten_bin_mac")
```

### Benefits

- **Reduced downloads**: Only downloads binaries for requested platforms
- **Faster setup**: Shorter download and extraction times
- **Storage efficiency**: Smaller local cache footprint
- **NPM optimization**: Only processes npm packages for used platforms
- **Bandwidth savings**: Particularly beneficial for CI/CD environments
- **Backward compatibility**: Default behavior unchanged (all platforms enabled)

### Implementation Pattern

The optimization follows the `npm.translate` pattern where extensions coordinate selective resource creation:

1. **Platform specification**: Users declare needed platforms via `emscripten_toolchain.platform()`
2. **Conditional repository creation**: Extension only creates `emscripten_bin_*` repositories for requested platforms
3. **Automatic toolchain registration**: Only registers toolchains for available platforms
4. **NPM coordination**: NPM translations reference only existing platform repositories

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
3. **Optimizes resource usage** - platform-specific downloads
4. **Improves maintainability**
5. **Aligns with Bazel best practices**
6. **Reduces bandwidth and storage requirements**
7. **Prepares for future Bazel versions**

## Verification

To verify the changes work correctly:

1. **Build without the flag**: `bazel build //hello-world:hello-world-wasm`
2. **Cross-platform builds**: Should work on Linux, macOS, and Windows
3. **Toolchain selection**: Bazel should automatically select the correct toolchain based on host platform
4. **Platform optimization**: Test selective platform downloads:
   ```starlark
   emscripten_toolchain.platform(name = "linux")
   # Verify only linux binaries are downloaded
   ```

## Conclusion

This modernization removes the dependency on a deprecated Bazel flag while maintaining full functionality and adding significant optimizations. The project now uses modern Bazel toolchain resolution patterns with platform-specific optimization that will be supported long-term. Users can now reduce download requirements by 80%+ by specifying only needed platforms, following the same pattern as other modern Bazel extensions like `npm.translate`.