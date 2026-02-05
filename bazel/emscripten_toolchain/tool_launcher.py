"""Emscripten tool launcher using hermetic Python from Bazel."""
import os
import sys
from pathlib import Path
import subprocess


def setup_emscripten_env():
    """Configure environment variables for Emscripten."""
    workspace_root = os.getenv('EXT_BUILD_ROOT', os.getcwd())
    bin_dir = os.getenv('EM_BIN_PATH', '')
    cfg_file = os.getenv('EM_CONFIG_PATH', '')
    
    em_path = Path(workspace_root) / bin_dir / 'emscripten'
    
    env_vars = os.environ.copy()
    env_vars['EMSCRIPTEN'] = str(em_path)
    env_vars['EM_CONFIG'] = str(Path(workspace_root) / cfg_file)
    
    return env_vars, em_path


def invoke_tool(tool_name, args):
    """Launch an Emscripten tool with hermetic Python."""
    env_vars, em_path = setup_emscripten_env()
    tool_path = em_path / f'{tool_name}.py'
    
    cmd = [sys.executable, str(tool_path)] + args
    proc = subprocess.run(cmd, env=env_vars)
    return proc.returncode


def main():
    script_name = Path(sys.argv[0]).stem
    
    # Determine which tool to invoke based on script name
    tool_mapping = {
        'emcc_launcher': 'emcc',
        'emar_launcher': 'emar',
    }
    
    tool = tool_mapping.get(script_name)
    if not tool:
        print(f"Error: Unknown launcher {script_name}", file=sys.stderr)
        sys.exit(1)
    
    exit_code = invoke_tool(tool, sys.argv[1:])
    sys.exit(exit_code)


if __name__ == '__main__':
    main()
