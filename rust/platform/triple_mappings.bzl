"""Helpers for constructing supported Rust platform triples"""

# CPUs that map to a "@platforms//cpu entry
_CPU_ARCH_TO_BUILTIN_PLAT_SUFFIX = {
    "x86_64": "x86_64",
    "powerpc": "ppc",
    "aarch64": "aarch64",
    "arm": "arm",
    "i686": "x86_32",
    "s390x": "s390x",
    "asmjs": None,
    "i386": "i386",
    "i586": None,
    "powerpc64": None,
    "powerpc64le": None,
    "armv7": "armv7",
    "armv7s": None,
    "s390": None,
    "le32": None,
    "mips": None,
    "mipsel": None,
    "wasm32": None,
}

# Systems that map to a "@platforms//os entry
_SYSTEM_TO_BUILTIN_SYS_SUFFIX = {
    "freebsd": "freebsd",
    "linux": "linux",
    "darwin": "osx",
    "windows": "windows",
    "ios": "ios",
    "android": "android",
    "none": "none",
    "emscripten": None,
    "unknown": None,
    "wasi": None,
    "nacl": None,
    "bitrig": None,
    "dragonfly": None,
    "netbsd": None,
    "openbsd": "openbsd",
    "solaris": None,
}

_SYSTEM_TO_BINARY_EXT = {
    "freebsd": "",
    "linux": "",
    "windows": ".exe",
    "darwin": "",
    "ios": "",
    "emscripten": ".js",
    # This is currently a hack allowing us to have the proper
    # generated extension for the wasm target, similarly to the
    # windows target
    "unknown": ".wasm",
    "wasi": ".wasm",
    "none": "",
}

_SYSTEM_TO_STATICLIB_EXT = {
    "freebsd": ".a",
    "linux": ".a",
    "darwin": ".a",
    "ios": ".a",
    "windows": ".lib",
    "emscripten": ".js",
    "unknown": "",
    "wasi": "",
    # This reflects Rust's behavior for the aarch64-unknown-none target,
    # which produces .a files when invoked to build a staticlib.
    "none": ".a",
}

_SYSTEM_TO_DYLIB_EXT = {
    "freebsd": ".so",
    "linux": ".so",
    "darwin": ".dylib",
    "ios": ".dylib",
    "windows": ".dll",
    "emscripten": ".js",
    # This is currently a hack allowing us to have the proper
    # generated extension for the wasm target, similarly to the
    # windows target
    "unknown": ".wasm",
    "wasi": ".wasm",
    "none": "",
}

# See https://github.com/rust-lang/rust/blob/master/src/libstd/build.rs
_SYSTEM_TO_STDLIB_LINKFLAGS = {
    # TODO(bazelbuild/rules_cc#75):
    #
    # Right now bazel cc rules does not specify the exact flag setup needed for calling out system
    # libs, that is we dont know given a toolchain if it should be, for example,
    # `-lxxx` or `/Lxxx` or `xxx.lib` etc.
    #
    # We include the flag setup as they are _commonly seen_ on various platforms with a cc_rules
    # style override for people doing things like gnu-mingw on windows.
    #
    # If you are reading this ... sorry! set the env var `BAZEL_RUST_STDLIB_LINKFLAGS` to
    # what you need for your specific setup, for example like so
    # `BAZEL_RUST_STDLIB_LINKFLAGS="-ladvapi32:-lws2_32:-luserenv"`
    "freebsd": ["-lexecinfo", "-lpthread"],
    # TODO: This ignores musl. Longer term what does Bazel think about musl?
    "linux": ["-ldl", "-lpthread"],
    "darwin": ["-lSystem", "-lresolv"],
    "uwp": ["ws2_32.lib"],
    "windows": ["advapi32.lib", "ws2_32.lib", "userenv.lib"],
    "ios": ["-lSystem", "-lobjc", "-framework Security", "-framework Foundation", "-lresolv"],
    # NOTE: Rust stdlib `build.rs` treats android as a subset of linux, rust rules treat android
    # as its own system.
    "android": ["-ldl", "-llog", "-lgcc"],
    "emscripten": [],
    "nacl": [],
    "bitrig": [],
    "dragonfly": ["-lpthread"],
    "netbsd": ["-lpthread", "-lrt"],
    "openbsd": ["-lpthread"],
    "solaris": ["-lsocket", "-lposix4", "-lpthread", "-lresolv"],
    "illumos": ["-lsocket", "-lposix4", "-lpthread", "-lresolv", "-lnsl", "-lumem"],
    "fuchsia": ["-lzircon", "-lfdio"],
    # TODO(gregbowyer): If rust stdlib is compiled for cloudabi with the backtrace feature it
    # includes `-lunwind` but this might not actually be required.
    # I am not sure which is the common configuration or how we encode it as a link flag.
    "cloudabi": ["-lunwind", "-lc", "-lcompiler_rt"],
    "unknown": [],
    "wasi": [],
    # We don't actually expect the stdlib to build for the "none" system,
    # but we don't need extra flags for it.
    "none": [],
}

def cpu_arch_to_constraints(cpu_arch):
    plat_suffix = _CPU_ARCH_TO_BUILTIN_PLAT_SUFFIX.get(cpu_arch)

    if plat_suffix:
        return ["@platforms//cpu:{}".format(plat_suffix)]

    if cpu_arch.startswith("riscv"):
        return ["@rules_rust//rust/platform/cpu:{}".format(cpu_arch)]

    fail("CPU architecture \"{}\" is not supported by rules_rust".format(cpu_arch))

def vendor_to_constraints(vendor):
    # TODO(acmcarther): Review:
    #
    # My current understanding is that vendors can't have a material impact on
    # constraint sets.
    return []

def system_to_constraints(system):
    sys_suffix = _SYSTEM_TO_BUILTIN_SYS_SUFFIX[system]

    if not sys_suffix:
        fail("System \"{}\" is not supported by rules_rust".format(sys_suffix))

    return ["@platforms//os:{}".format(sys_suffix)]

def abi_to_constraints(abi):
    # TODO(acmcarther): Implement when C++ toolchain is more mature and we
    # figure out how they're doing this
    return []

def triple_to_system(triple):
    """Returns a system name for a given platform triple

    Args:
        triple (str): A platform triple. eg: `x86_64-unknown-linux-gnu`

    Returns:
        str: A system name
    """
    if triple == "wasm32-wasi":
        return "wasi"

    component_parts = triple.split("-")
    if len(component_parts) < 3:
        fail("Expected target triple to contain at least three sections separated by '-'")

    return component_parts[2]

def system_to_dylib_ext(system):
    return _SYSTEM_TO_DYLIB_EXT[system]

def system_to_staticlib_ext(system):
    return _SYSTEM_TO_STATICLIB_EXT[system]

def system_to_binary_ext(system):
    return _SYSTEM_TO_BINARY_EXT[system]

def system_to_stdlib_linkflags(system):
    return _SYSTEM_TO_STDLIB_LINKFLAGS[system]

def triple_to_constraint_set(triple):
    """Returns a set of constraints for a given platform triple

    Args:
        triple (str): A platform triple. eg: `x86_64-unknown-linux-gnu`

    Returns:
        list: A list of constraints (each represented by a list of strings)
    """
    if triple == "wasm32-wasi":
        return [
            "@rules_rust//rust/platform/cpu:wasm32",
            "@rules_rust//rust/platform/os:wasi",
        ]
    if triple == "wasm32-unknown-unknown":
        return [
            "@rules_rust//rust/platform/cpu:wasm32",
            "@rules_rust//rust/platform/os:unknown",
        ]

    component_parts = triple.split("-")
    if len(component_parts) < 3:
        fail("Expected target triple to contain at least three sections separated by '-'")

    cpu_arch = component_parts[0]
    vendor = component_parts[1]
    system = component_parts[2]
    abi = None

    if len(component_parts) == 4:
        abi = component_parts[3]

    constraint_set = []
    constraint_set += cpu_arch_to_constraints(cpu_arch)
    constraint_set += vendor_to_constraints(vendor)
    constraint_set += system_to_constraints(system)
    constraint_set += abi_to_constraints(abi)

    return constraint_set
