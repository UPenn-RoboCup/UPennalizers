# WELCOME 
# This is the main cmake configuration file 
# associated with your project
# You can define specific compilation options here
# More about cmake : www.cmake.org
# Using cmake command line : 
# 1. Create a build directory : mkdir build
# 2. Configure cmake project : cd build; cmake ..
#   You can also generate project with your favorite IDE : 
#   Example : For Mac osx use "cmake .. -G XCode"
#   see cmake help for more information
# 3. Edit project option : ccmake .
# 4. Build it : make 

cmake_minimum_required(VERSION 2.6.4 FATAL_ERROR)

include_directories( ../Lua/src )
link_directories( ../Lua/src/build )

# pre 1.12 way
#create_module(dcmlua)
# post 1.12
project(dcmlua)

add_library ( dcmlua SHARED
    src/dcmprocess.cpp
    src/dcmprocess.h

    src/luafifo.cpp
    src/luafifo.h

    src/shm_util.cpp
    src/shm_util.h

    src/sensor_process.cpp
    src/sensor_process.h
    src/actuator_process.cpp
    src/actuator_process.h
)

# pre 1.12
#configure_src_module( dcmlua ${dcmlua_SRCS} )
# post 1.12
#qi_create_lib( dcmlua ${dcmlua_SRCS} SHARED SUBFOLDER naoqi )

#add_library( lua STATIC IMPORTED )
#set_property( TARGET lua PROPERTY IMPORTED_LOCATION /usr/local/lib/liblua.a )
#target_link_libraries( dcmlua lua )
target_link_libraries( dcmlua almemoryfastaccess )

set_target_properties(dcmlua PROPERTIES PREFIX "")
# pre 1.12
#use_lib( dcmlua ALCOMMON )
# post 1.12
#qi_use_lib( dcmlua ALCOMMON )
# TODO: might need this:
#qi_use_lib( dcmlua ALMEMORYFASTACCESS )

