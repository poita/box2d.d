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
else()
    target_compile_options(box2d PRIVATE -Wall)
endif()
