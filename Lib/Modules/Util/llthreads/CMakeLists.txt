cmake_minimum_required( VERSION 2.8.0 )
project( llthreads )

#include_directories(AFTER SYSTEM ./)
#include_directories(AFTER SYSTEM /usr/local/include/)
#include_directories(AFTER SYSTEM /usr/include/)
#include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

set( llthreads_srcs 
  lua_llthreads.c
  l52util.c
)

add_library(
  llthreads
  SHARED
  ${llthreads_srcs} )


set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set_target_properties(llthreads
                      PROPERTIES PREFIX  ""
                      SUFFIX ".so")

target_link_libraries(llthreads -lm)
target_link_libraries(llthreads -llua)
