cmake_minimum_required( VERSION 2.8.0 )
project( Jpeg )

#include_directories(AFTER SYSTEM ./)
#include_directories(AFTER SYSTEM /usr/local/include/)
#include_directories(AFTER SYSTEM /usr/include/)
#include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

set( Jpeg_srcs 
  lua_jpeg.cpp
)

add_library(
  jpeg
  SHARED
  ${Jpeg_srcs} )


set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set_target_properties(jpeg
                      PROPERTIES PREFIX  ""
                      SUFFIX ".so")

target_link_libraries(jpeg -lm)
target_link_libraries(jpeg -llua)
