# CMakeLists.txt for beam_vm Flutter plugin
# This plugin provides JNI bindings for the BEAM VM

cmake_minimum_required(VERSION 3.22.1)
project("beam_vm" LANGUAGES CXX)

# Find liberlang.a from the host app's jniLibs directory
# Users must place liberlang.a in their app's android/app/src/main/jniLibs/{ABI}/
# The path is passed via LIBERLANG_DIR or we search common locations
if(DEFINED LIBERLANG_DIR)
    set(ERLANG_LIB_PATH "${LIBERLANG_DIR}/liberlang.a")
else()
    # Default: look in the app's jniLibs directory
    # This path resolves when building the host app, not the plugin
    set(ERLANG_LIB_PATH "${CMAKE_SOURCE_DIR}/../../../app/src/main/jniLibs/${ANDROID_ABI}/liberlang.a")
endif()

message(STATUS "Looking for liberlang.a at: ${ERLANG_LIB_PATH}")

# Check if liberlang exists (warning only, actual build happens in host app context)
if(EXISTS "${ERLANG_LIB_PATH}")
    message(STATUS "Found liberlang.a")

    # Import liberlang as static library
    add_library(erlang STATIC IMPORTED)
    set_target_properties(erlang PROPERTIES
        IMPORTED_LOCATION "${ERLANG_LIB_PATH}"
    )
    set(HAVE_ERLANG TRUE)
else()
    message(WARNING "liberlang.a not found at ${ERLANG_LIB_PATH}")
    message(WARNING "Download from: https://github.com/Gao-OS/mobile-BEAM-OTP/releases")
    message(WARNING "Place in: android/app/src/main/jniLibs/{ABI}/liberlang.a")
    set(HAVE_ERLANG FALSE)
endif()

# Create the native library
add_library(beam_vm SHARED
    beam_vm_native.cpp
)

# Include directories
target_include_directories(beam_vm PRIVATE
    ${CMAKE_SOURCE_DIR}
)

# Link libraries
target_link_libraries(beam_vm
    android
    log
    z
    m
    dl
)

# Link erlang if available
if(HAVE_ERLANG)
    target_link_libraries(beam_vm erlang)
    target_compile_definitions(beam_vm PRIVATE HAVE_ERLANG=1)
endif()

# C++ standard
set_target_properties(beam_vm PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)
