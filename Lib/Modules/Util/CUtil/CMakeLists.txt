cmake_minimum_required(VERSION 2.6.4 FATAL_ERROR)

project(CUtil)

# include for lua headers
include_directories(../../../Lua/src)

# cutil main library definition
add_library(cutil SHARED luacutil.cpp)

# set optimization level
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

# set library prefix to "" otherwise it will create libcutil.so
set_target_properties(cutil PROPERTIES PREFIX "")

