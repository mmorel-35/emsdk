#!/bin/bash

export ROOT_DIR=${EXT_BUILD_ROOT:-$(pwd -P)}
export EMSCRIPTEN=$ROOT_DIR/$EM_BIN_PATH/emscripten
export EM_CONFIG=$ROOT_DIR/$EM_CONFIG_PATH

# Find a suitable Python interpreter (requires 3.10+ for match statement support)
find_python() {
  for py_cmd in python3.13 python3.12 python3.11 python3.10 python3; do
    if command -v "$py_cmd" >/dev/null 2>&1; then
      # Verify Python version is 3.10 or higher
      version=$("$py_cmd" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)
      if [ $? -eq 0 ]; then
        major=$(echo "$version" | cut -d. -f1)
        minor=$(echo "$version" | cut -d. -f2)
        if [ "$major" -eq 3 ] && [ "$minor" -ge 10 ]; then
          echo "$py_cmd"
          return 0
        fi
      fi
    fi
  done
  echo "Error: Python 3.10 or higher is required for Emscripten" >&2
  exit 1
}
