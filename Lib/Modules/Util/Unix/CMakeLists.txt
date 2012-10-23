cmake_minimum_required(VERSION 2.6.4 FATAL_ERROR)

project(LuaUnix)

# include for lua headers
include_directories(../../../Lua/src)

# unix main library definition
add_library(unix SHARED luaunix.c)

# getch main library definition
add_library(getch SHARED getch.c)

# stty main library definition
add_library(stty SHARED luastty.cpp)

# set optimization level
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

# set library prefix to "" otherwise it will create libunix.so
set_target_properties(unix PROPERTIES PREFIX "")
set_target_properties(getch PROPERTIES PREFIX "")
set_target_properties(stty PROPERTIES PREFIX "")

