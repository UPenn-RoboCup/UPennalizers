cmake_minimum_required( VERSION 2.8.0 )
project( Z )

set(CC "mex")
set(CXX "mex")

include_directories(AFTER SYSTEM ./)
include_directories(AFTER SYSTEM /usr/local/include/)
include_directories(AFTER SYSTEM /usr/include/)
include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

set( Zlib_srcs 
  lua_z.cpp
  zlib-src/deflate.c 
  zlib-src/inflate.c 
  zlib-src/inffast.c 
  zlib-src/inftrees.c 
  zlib-src/trees.c 
  zlib-src/adler32.c 
  zlib-src/crc32.c 
  zlib-src/zutil.c
)

add_library(
  Z
  SHARED
  ${Zlib_srcs} )


set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set_target_properties(Z
          PROPERTIES PREFIX  ""
          SUFFIX ".so")


target_link_libraries(Z -lm -llua)


