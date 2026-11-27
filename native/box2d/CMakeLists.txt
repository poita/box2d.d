# Minimal static-library build of Box2D for the box2d.d bindings.
# Compiles only the core library (no samples/tests/docs) so it can be built
# self-contained on any platform with a C17 compiler.
cmake_minimum_required(VERSION 3.16)
project(box2d_native LANGUAGES C)

file(GLOB BOX2D_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c")

add_library(box2d STATIC ${BOX2D_SOURCES})

target_include_directories(box2d
    PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include"
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")

# Box2D requires C17 for _Static_assert and anonymous unions.
set_target_properties(box2d PROPERTIES
    C_STANDARD 17
    C_STANDARD_REQUIRED YES
    C_EXTENSIONS YES
    POSITION_INDEPENDENT_CODE ON)

if(MSVC)
    target_compile_options(box2d PRIVATE /W3)
    # Link the static CRT to match what LDC links by default. With CMake's default
    # dynamic CRT the C objects reference the UCRT through import symbols while the
    # D linker supplies the static libucrt, leaving b2Alloc's _aligned_malloc and
    # b2Free's _aligned_free unresolved.
    set_property(TARGET box2d PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
    # The 8-wide contact solver uses AVX2 intrinsics; Box2D picks it at runtime via
    # cpuid, so only this file is compiled for AVX2 (clang-cl and gcc/clang use
    # target attributes instead).
    if(NOT CMAKE_C_COMPILER_ID STREQUAL "Clang" AND CMAKE_C_COMPILER_ARCHITECTURE_ID MATCHES "^(x64|X86)$")
        set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/src/contact_solver_w8.c"
            PROPERTIES COMPILE_OPTIONS "/arch:AVX2")
    endif()
else()
    target_compile_options(box2d PRIVATE -Wall -Wno-unused-value)
endif()
