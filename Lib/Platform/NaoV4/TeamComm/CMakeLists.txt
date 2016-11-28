cmake_minimum_required( VERSION 2.8.0 )
project( TeamComm )

#include_directories(AFTER SYSTEM ./)
#include_directories(AFTER SYSTEM /usr/local/include/)
#include_directories(AFTER SYSTEM /usr/include/)
#include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

add_library(
  TeamComm
  SHARED
  lua_TeamComm.cpp
  )



set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set_target_properties(TeamComm
					PROPERTIES PREFIX  ""
					SUFFIX ".so")


target_link_libraries(TeamComm -lm -llua)