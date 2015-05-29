##
## Copyright (C) 2010 Aldebaran Robotics
##

###############################################
# Auto-generated file.                        #
# Do not edit                                 #
# This file is part of the T001CHAIN project  #
###############################################

set(BOOTSTRAP_VERSION 2)

if (NOT CMAKE_TOOLCHAIN_FILE)
  message(STATUS
    "
    No toolchain file has been sepcified.
    (CMAKE_TOOLCHAIN_FILE variable is not defined)

    Please delete the CMake cache, specify a valid
    toolchain file and try again.

    Example:

      cd build
      rm -f CMakeCache.txt
      cmake -DCMAKE_TOOLCHAIN_FILE=/path/to/naoqi-sdk/toolchain.cmake ..

    "
  )
  message(FATAL_ERROR "")
endif()


if (NOT TOOLCHAIN_DIR STREQUAL "")
  set(T001CHAIN_DIR ${TOOLCHAIN_DIR} CACHE PATH "" FORCE)
endif (NOT TOOLCHAIN_DIR STREQUAL "")

include("${T001CHAIN_DIR}/cmake/general.cmake")
