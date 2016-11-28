cmake_minimum_required( VERSION 2.8.0 )
project( Unix )

#include_directories(AFTER SYSTEM ./)
#include_directories(AFTER SYSTEM /usr/local/include/)
#include_directories(AFTER SYSTEM /usr/include/)
#include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

add_library(
  getch
  SHARED
  lua_getch.c)

  add_library(
  invhyp
  SHARED
  lua_invhyp.c)

  add_library(
  signal
  SHARED
  lua_signal.c)

  add_library(
  unix
  SHARED
  luaunix.c)

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")

  add_library(
    serial
    SHARED
    luaserial.c)


    set_target_properties(serial
        PROPERTIES PREFIX  ""
        SUFFIX ".so")


    target_link_libraries(serial -lm -llua)


endif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")




  add_library(
  stty
  SHARED
  luastty.cpp)


set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set_target_properties(getch
					PROPERTIES PREFIX  ""
					SUFFIX ".so")

set_target_properties(invhyp
				PROPERTIES PREFIX  ""
				SUFFIX ".so")


set_target_properties(signal
				PROPERTIES PREFIX  ""
				SUFFIX ".so")

set_target_properties(unix
				PROPERTIES PREFIX  ""
				SUFFIX ".so")

set_target_properties(stty
				PROPERTIES PREFIX  ""
				SUFFIX ".so")

target_link_libraries(getch -lm -llua)
target_link_libraries(invhyp -lm -llua)
target_link_libraries(signal -lm -llua)
target_link_libraries(unix -lm -llua)

target_link_libraries(stty -lm -llua)
