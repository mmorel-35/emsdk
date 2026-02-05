#!/bin/bash

source $(dirname $0)/env.sh

# Use hermetic Python launcher from py_binary
LAUNCHER="$(dirname $0)/emcc_launcher"
if [ -x "$LAUNCHER" ]; then
    exec "$LAUNCHER" "$@"
else
    # Fallback to direct python3 invocation
    exec python3 $EMSCRIPTEN/emcc.py "$@"
fi
