# CMakeLists.txt for BeamTest E2E Android app
# Links liberlang.a and compiles beam-test native code

cmake_minimum_required(VERSION 3.22.1)
project("beamtest")

# Path to liberlang.a built by mobile-BEAM-OTP
# CMAKE_SOURCE_DIR is test/e2e/apps/android/app/src/main/cpp/
# Go up 8 levels to reach project root, then into _build/{arch}
set(LIBERLANG_DIR "${CMAKE_SOURCE_DIR}/../../../../../../../../_build/${ANDROID_ABI}")

# Check if liberlang.a exists
if(NOT EXISTS "${LIBERLANG_DIR}/liberlang.a")
    message(WARNING "liberlang.a not found at ${LIBERLANG_DIR}/liberlang.a")
    message(WARNING "Run 'mix package.android.runtime' first to build the BEAM runtime")
endif()

# Import liberlang as a static library
add_library(erlang STATIC IMPORTED)
set_target_properties(erlang PROPERTIES
    IMPORTED_LOCATION "${LIBERLANG_DIR}/liberlang.a"
)

# Erlang includes from OTP source
# Note: Headers are packaged with the runtime
set(ERLANG_INCLUDE_DIR "${LIBERLANG_DIR}/include")

# Create native test library
add_library(beam-test SHARED
    beam-test.cpp
)

# Include directories
target_include_directories(beam-test PRIVATE
    ${ERLANG_INCLUDE_DIR}
)

# Link libraries
target_link_libraries(beam-test
    erlang
    android
    log
    z                # zlib
    m                # math
    dl               # dynamic loading
)

# C++ standard
set_target_properties(beam-test PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)
