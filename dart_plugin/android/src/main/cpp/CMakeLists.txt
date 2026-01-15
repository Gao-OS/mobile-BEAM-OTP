# CMakeLists.txt for beam_vm Flutter plugin
# This plugin provides JNI bindings for the BEAM VM

cmake_minimum_required(VERSION 3.22.1)
project("beam_vm" LANGUAGES CXX)

# Find liberlang.a from the host app's jniLibs directory
# Users must place liberlang.a in their app's android/app/src/main/jniLibs/{ABI}/
# The path is passed via LIBERLANG_DIR or we search common locations
set(ERLANG_LIB_PATH "")
set(ERLANG_LIB_FOUND FALSE)

if(DEFINED LIBERLANG_DIR AND EXISTS "${LIBERLANG_DIR}/liberlang.a")
    set(ERLANG_LIB_PATH "${LIBERLANG_DIR}/liberlang.a")
    set(ERLANG_LIB_FOUND TRUE)
    message(STATUS "Found liberlang.a via LIBERLANG_DIR: ${ERLANG_LIB_PATH}")
else()
    # Search multiple possible locations for liberlang.a
    # Priority order: project jniLibs, build directory, well-known locations
    set(SEARCH_PATHS
        # Host app's jniLibs (standard Flutter plugin context)
        "${CMAKE_SOURCE_DIR}/../../../app/src/main/jniLibs/${ANDROID_ABI}/liberlang.a"
        # Alternative: relative to project root
        "${CMAKE_SOURCE_DIR}/../../../../app/src/main/jniLibs/${ANDROID_ABI}/liberlang.a"
        # Build output location
        "${CMAKE_BINARY_DIR}/../../../jniLibs/${ANDROID_ABI}/liberlang.a"
    )

    foreach(SEARCH_PATH ${SEARCH_PATHS})
        if(EXISTS "${SEARCH_PATH}")
            get_filename_component(ERLANG_LIB_PATH "${SEARCH_PATH}" ABSOLUTE)
            set(ERLANG_LIB_FOUND TRUE)
            message(STATUS "Found liberlang.a at: ${ERLANG_LIB_PATH}")
            break()
        endif()
    endforeach()
endif()

if(NOT ERLANG_LIB_FOUND)
    message(STATUS "Searched paths for liberlang.a:")
    message(STATUS "  CMAKE_SOURCE_DIR: ${CMAKE_SOURCE_DIR}")
    message(STATUS "  CMAKE_BINARY_DIR: ${CMAKE_BINARY_DIR}")
    message(STATUS "  ANDROID_ABI: ${ANDROID_ABI}")
endif()

# Configure liberlang linking if found
if(ERLANG_LIB_FOUND)
    # Import liberlang as static library
    add_library(erlang STATIC IMPORTED)
    set_target_properties(erlang PROPERTIES
        IMPORTED_LOCATION "${ERLANG_LIB_PATH}"
    )
    set(HAVE_ERLANG TRUE)
else()
    message(WARNING "liberlang.a not found!")
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
