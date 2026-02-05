#!/bin/bash

source $(dirname $0)/env.sh

exec $(find_python) $EMSCRIPTEN/emar.py "$@"
