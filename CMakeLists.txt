cmake_minimum_required(VERSION 3.25)

project(fgof_termios VERSION 0.1.0 LANGUAGES Fortran C)

add_library(fgof_termios
  src/fgof_termios_types.f90
  src/fgof_termios_posix.f90
  src/fgof_termios.f90
  src/fgof_termios_posix.c
)
add_library(fgof::termios ALIAS fgof_termios)

set_target_properties(fgof_termios PROPERTIES
  Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod"
)

target_include_directories(fgof_termios PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/mod>
)

target_compile_options(fgof_termios PRIVATE
  $<$<COMPILE_LANG_AND_ID:Fortran,GNU>:-std=f2018 -Wall -Wextra -Wpedantic -Werror>
  $<$<COMPILE_LANG_AND_ID:C,GNU,Clang,AppleClang>:-Wall -Wextra -Wpedantic -Werror>
)
