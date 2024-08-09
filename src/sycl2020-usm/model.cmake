
register_flag_optional(CMAKE_CXX_COMPILER
        "Any CXX compiler that is supported by CMake detection, this is used for host compilation when required by the SYCL compiler"
        "c++")

macro(setup)
    set(CMAKE_CXX_STANDARD 17)


endmacro()


