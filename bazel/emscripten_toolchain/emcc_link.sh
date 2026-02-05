#!/bin/bash

source $(dirname $0)/env.sh

exec $(find_python) $(dirname $0)/link_wrapper.py "$@"
