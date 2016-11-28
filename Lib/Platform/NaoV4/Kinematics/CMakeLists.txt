cmake_minimum_required( VERSION 2.8.0 )
project( NaoKinematics )

#include_directories(AFTER SYSTEM ./)
#include_directories(AFTER SYSTEM /usr/local/include/)
#include_directories(AFTER SYSTEM /usr/include/)
#include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

add_library(
  NaoKinematics
  SHARED
  lua_NaoKinematics.cpp
  naoKinematics.cpp
  Transform.cpp
  )



set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set_target_properties(NaoKinematics
					PROPERTIES PREFIX  ""
					SUFFIX ".so")


target_link_libraries(NaoKinematics -lm -llua)