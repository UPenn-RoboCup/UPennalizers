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

include("${CMAKE_CURRENT_SOURCE_DIR}/bootstrap.cmake")
use(NAOQI-PLUGINS-TOOLS)

include_directories( /usr/local/include )
link_directories( /usr/local/lib )

create_module(dcmlua)

SET ( dcmlua_SRCS
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

configure_src_module( dcmlua ${dcmlua_SRCS} )

#add_library( lua STATIC IMPORTED )
#set_property( TARGET lua PROPERTY IMPORTED_LOCATION /usr/local/lib/liblua.a )
target_link_libraries( dcmlua lua )
target_link_libraries( dcmlua almemoryfastaccess )

use_lib( dcmlua ALCOMMON )
