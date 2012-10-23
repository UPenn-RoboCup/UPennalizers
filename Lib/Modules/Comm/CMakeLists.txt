cmake_minimum_required(VERSION 2.6.4 FATAL_ERROR)

project(LuaComm)

# include for lua headers
include_directories(../../Lua/src)

# Comm main library definition
add_library(Comm SHARED luaComm.cpp)

# set optimization level
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

# set library prefix to "" otherwise it will create libComm.so
set_target_properties(Comm PROPERTIES PREFIX "")

target_link_libraries(Comm m)
