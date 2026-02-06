"""Centralized platform definitions and utilities for Emscripten toolchain."""

# Standard platform mappings between Bazel constraints and internal platform names
PLATFORM_MAPPINGS = {
    # (os_constraint, cpu_constraint): internal_platform_name
    ("linux", "x86_64"): "linux", 
    ("linux", "arm64"): "linux_arm64",
    ("macos", "x86_64"): "mac",
    ("macos", "arm64"): "mac_arm64", 
    ("windows", "x86_64"): "win",
}

# Reverse mapping for lookups
INTERNAL_TO_CONSTRAINTS = {v: k for k, v in PLATFORM_MAPPINGS.items()}

# All supported platform names
ALL_PLATFORMS = list(PLATFORM_MAPPINGS.values())

def constraint_to_platform_name(constraints):
    """Convert platform constraints to internal platform name.
    
    Args:
        constraints: List of Bazel platform constraint strings
        
    Returns:
        Internal platform name string
        
    Raises:
        fail() if constraints are invalid or unsupported
    """
    os_constraint = None
    cpu_constraint = None
    
    for constraint in constraints:
        if constraint.startswith("@platforms//os:"):
            os_constraint = constraint[len("@platforms//os:"):]
        elif constraint.startswith("@platforms//cpu:"):
            cpu_constraint = constraint[len("@platforms//cpu:"):]
    
    if not os_constraint or not cpu_constraint:
        fail("Platform must specify both OS and CPU constraints. Got: {}".format(constraints))
    
    platform_key = (os_constraint, cpu_constraint)
    if platform_key not in PLATFORM_MAPPINGS:
        supported = ["{}/{}".format(os, cpu) for os, cpu in PLATFORM_MAPPINGS.keys()]
        fail("Unsupported platform combination: {}/{}. Supported: {}".format(
            os_constraint, cpu_constraint, ", ".join(supported)))
    
    return PLATFORM_MAPPINGS[platform_key]

def platform_name_to_constraints(platform_name):
    """Convert internal platform name to Bazel constraints.
    
    Args:
        platform_name: Internal platform name
        
    Returns:
        List of constraint strings
        
    Raises:
        fail() if platform_name is not supported
    """
    if platform_name not in INTERNAL_TO_CONSTRAINTS:
        fail("Unknown platform name: {}. Supported: {}".format(
            platform_name, ", ".join(ALL_PLATFORMS)))
    
    os_constraint, cpu_constraint = INTERNAL_TO_CONSTRAINTS[platform_name]
    return [
        "@platforms//os:{}".format(os_constraint),
        "@platforms//cpu:{}".format(cpu_constraint),
    ]

def detect_host_platform(ctx):
    """Detect the host platform based on Bazel's os and arch information.
    
    Args:
        ctx: Repository or module extension context
        
    Returns:
        Internal platform name for the detected host
    """
    if ctx.os.name.startswith("linux"):
        if ctx.os.arch == "aarch64" or ctx.os.arch == "arm64":
            return "linux_arm64"
        else:
            return "linux"
    elif ctx.os.name.startswith("mac"):
        if ctx.os.arch == "aarch64" or ctx.os.arch == "arm64":
            return "mac_arm64"
        else:
            return "mac"
    elif ctx.os.name.startswith("windows"):
        return "win"
    else:
        # Fallback to linux for unknown platforms
        return "linux"
