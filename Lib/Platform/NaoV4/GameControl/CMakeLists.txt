cmake_minimum_required( VERSION 2.8.0 )
project( GameControlReceiver )

#include_directories(AFTER SYSTEM ./)
#include_directories(AFTER SYSTEM /usr/local/include/)
#include_directories(AFTER SYSTEM /usr/include/)
#include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

add_library(
  GameControlReceiver
  SHARED
  lua_GameControlReceiver.cc
  timeScalar.cc
  )



set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set_target_properties(GameControlReceiver
					PROPERTIES PREFIX  ""
					SUFFIX ".so")


target_link_libraries(GameControlReceiver -lm -llua)