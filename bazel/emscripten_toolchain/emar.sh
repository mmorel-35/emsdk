#!/bin/bash

source $(dirname $0)/env.sh
source $(dirname $0)/find_python.sh

exec "$PY_EXEC" $EMSCRIPTEN/emar.py "$@"
