cmake_minimum_required(VERSION 2.6.4 FATAL_ERROR)

project(LuaShm)

# include for lua headers
include_directories(../../../Lua/src)

# shm main library definition
add_library(shm SHARED luashm.cpp)

# set optimization level (shm cannot be higher than 1)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O1")

# set library prefix to "" otherwise it will create libshm.so
set_target_properties(shm PROPERTIES PREFIX "")

# link to rt for shared memory ipc
target_link_libraries(shm rt)

