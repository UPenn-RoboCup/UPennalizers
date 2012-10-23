cmake_minimum_required(VERSION 2.6.4 FATAL_ERROR)

project(CArray)

# include for lua headers
include_directories(../../../Lua/src)

# carray main library definition
add_library(carray SHARED luacarray.cpp)

# set optimization level
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

# set library prefix to "" otherwise it will create libcarray.so
set_target_properties(carray PROPERTIES PREFIX "")

