cmake_minimum_required(VERSION 3.20)

project(
  ring_buffer_showcase
  VERSION 0.1.0
  LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(ring_buffer_demo src/main.cpp)

target_include_directories(ring_buffer_demo PRIVATE src)

# Warning flags are compiler-specific. `-Wextra` is not a thing MSVC understands - it reports
# `invalid numeric argument '/Wextra'` and the build dies at the command line, before compiling
# anything.
if(MSVC)
  target_compile_options(ring_buffer_demo PRIVATE /W4 /permissive-)
else()
  target_compile_options(ring_buffer_demo PRIVATE -Wall -Wextra -Wpedantic)
endif()
