cmake_minimum_required( VERSION 2.8.0 )
project( OldComm )

#include_directories(AFTER SYSTEM ./)
#include_directories(AFTER SYSTEM /usr/local/include/)
#include_directories(AFTER SYSTEM /usr/include/)
#include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

set( OldComm_srcs 
  luaComm.cpp
)

add_library(
  OldComm
  SHARED
  ${OldComm_srcs} )


set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set_target_properties(OldComm
                      PROPERTIES PREFIX  ""
                      SUFFIX ".so")

target_link_libraries(OldComm -lm)
target_link_libraries(OldComm -llua)
#target_link_libraries(OldComm -lalmemoryfastaccess)



if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  message(UNIX: " Adding lrt library"  )
  target_link_libraries(OldComm -lrt)
endif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
