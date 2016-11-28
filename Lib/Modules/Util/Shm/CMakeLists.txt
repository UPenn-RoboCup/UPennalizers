cmake_minimum_required( VERSION 2.8.0 )
project( Shm )

#include_directories(AFTER SYSTEM ./)
#include_directories(AFTER SYSTEM /usr/local/include/)
#include_directories(AFTER SYSTEM /usr/include/)
#include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

set( Shm_srcs 
  lua_shm.cpp
)

add_library(
  shm
  SHARED
  ${Shm_srcs} )


set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set_target_properties(shm
                      PROPERTIES PREFIX  ""
                      SUFFIX ".so")

target_link_libraries(shm -lm)
target_link_libraries(shm -llua)
