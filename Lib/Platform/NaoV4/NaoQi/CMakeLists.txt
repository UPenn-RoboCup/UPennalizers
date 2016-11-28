cmake_minimum_required( VERSION 2.8.0 )
project( luadcm )

include_directories(AFTER SYSTEM ./)
include_directories(AFTER SYSTEM /usr/local/include/)
include_directories(AFTER SYSTEM /usr/include/)
include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

set( luadcm_srcs 
  src/actuator_process.cpp
  src/dcmprocess.cpp
  src/luadcm.cpp
  src/luafifo.cpp
  src/sensor_process.cpp
  src/shmmap.cpp
  src/shm_util.cpp
)

add_library(
  luadcm
  SHARED
  ${luadcm_srcs} )


set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

target_link_libraries(luadcm -lm)
target_link_libraries(luadcm -llua)
target_link_libraries(luadcm -lalmemoryfastaccess)


if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  message(UNIX: " Adding lrt library"  )
  target_link_libraries(luadcm -lrt)
endif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
