cmake_minimum_required( VERSION 2.8.0 )
project( CUtil )

#include_directories(AFTER SYSTEM ./)
#include_directories(AFTER SYSTEM /usr/local/include/)
#include_directories(AFTER SYSTEM /usr/include/)
#include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

set( CUtil_srcs 
  lua_cutil.cpp
)

add_library(
  cutil
  SHARED
  ${CUtil_srcs} )


set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set_target_properties(cutil
                      PROPERTIES PREFIX  ""
                      SUFFIX ".so")

target_link_libraries(cutil -lm)
target_link_libraries(cutil -llua)
