#!/bin/bash

export ROOT_DIR=${EXT_BUILD_ROOT:-$(pwd -P)}
export EMSCRIPTEN=$ROOT_DIR/$EM_BIN_PATH/emscripten
export EM_CONFIG=$ROOT_DIR/$EM_CONFIG_PATH

# Find a suitable Python interpreter (requires 3.10+ for match statement support)
find_python() {
  for py_cmd in python3.13 python3.12 python3.11 python3.10 python3; do
    if command -v "$py_cmd" >/dev/null 2>&1; then
      echo "$py_cmd"
      return 0
    fi
  done
  echo "python3"
}
