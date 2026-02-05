#!/bin/bash
# Locates a Python interpreter that meets minimum version requirements for Emscripten.
# Sets PY_EXEC variable to the path of a suitable interpreter.

find_suitable_python() {
    local MIN_MAJOR=3
    local MIN_MINOR=10
    
    # Try versioned executables first (most likely to be newer)
    for ver in 3.13 3.12 3.11 3.10; do
        local cmd="python${ver}"
        if command -v "$cmd" &> /dev/null; then
            PY_EXEC="$cmd"
            return 0
        fi
    done
    
    # Try generic python3, but verify version
    if command -v python3 &> /dev/null; then
        local ver_output
        ver_output=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)
        
        if [[ -n "$ver_output" ]]; then
            local major minor
            IFS='.' read -r major minor <<< "$ver_output"
            
            if [[ "$major" -eq $MIN_MAJOR && "$minor" -ge $MIN_MINOR ]]; then
                PY_EXEC="python3"
                return 0
            fi
        fi
    fi
    
    # No suitable Python found
    echo "FATAL: Emscripten 5.0.0+ requires Python ${MIN_MAJOR}.${MIN_MINOR} or newer" >&2
    echo "Please install Python 3.10+ and ensure it's in your PATH" >&2
    return 1
}

# Execute the finder
find_suitable_python || exit 1
