cmake_minimum_required(VERSION 3.16)
project(z8000_emu
  LANGUAGES CXX
  VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
  message(FATAL_ERROR "Building within the source tree is unsupported")
endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

add_compile_options(-Wall -Wextra)

include(GNUInstallDirs)

option(BUILD_DRIVER "Build the z8000emu driver" ON)
option(BUILD_TOOLS "Build z8000emu tools" ON)
option(BUILD_TESTS "Build and run emulator tests" OFF)

add_subdirectory(lib)

if(BUILD_DRIVER)
  add_subdirectory(src)
endif()

if(BUILD_TOOLS)
  add_subdirectory(tools)
endif()

if(BUILD_TESTS)
  add_subdirectory(tests)
endif()
