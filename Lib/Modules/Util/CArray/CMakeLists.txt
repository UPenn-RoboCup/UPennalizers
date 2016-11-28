cmake_minimum_required( VERSION 2.8.0 )
project( CArray )

#include_directories(AFTER SYSTEM ./)
#include_directories(AFTER SYSTEM /usr/local/include/)
#include_directories(AFTER SYSTEM /usr/include/)
#include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

set( CArray_srcs 
  lua_carray.cpp
)

add_library(
  carray
  SHARED
  ${CArray_srcs} )


set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set_target_properties(carray
                      PROPERTIES PREFIX  ""
                      SUFFIX ".so")

target_link_libraries(carray -lm)
target_link_libraries(carray -llua)
