cmake_minimum_required(VERSION 2.6.4 FATAL_ERROR)

project(NaoKinematics)

# include for lua headers
include_directories(../../../Lua/src)

# main library definition
add_library(NaoKinematics SHARED luaNaoKinematics.cpp naoKinematics.cpp Transform.cpp)

# set optimization level
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

# set library prefix to "" otherwise it will create libNaoKinematics.so
set_target_properties(NaoKinematics PROPERTIES PREFIX "")

# link to math library
target_link_libraries(NaoKinematics m)

