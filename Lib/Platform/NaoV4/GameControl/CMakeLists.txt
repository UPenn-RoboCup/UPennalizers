cmake_minimum_required(VERSION 2.6.4 FATAL_ERROR)

project(NaoGameControlReceiver)

# include for lua headers
include_directories(../../../Lua/src)

# main library definition
add_library(NaoGameControlReceiver SHARED luaNaoGameControlReceiver.cc timeScalar.cc)

# set optimization level
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

# set library prefix to "" otherwise it will create libNaoGameControlReceiver.so
set_target_properties(NaoGameControlReceiver PROPERTIES PREFIX "")

# link to math library
target_link_libraries(NaoGameControlReceiver m)

