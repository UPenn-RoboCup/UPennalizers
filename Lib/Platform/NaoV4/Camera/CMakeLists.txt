cmake_minimum_required(VERSION 2.6.4 FATAL_ERROR)

project(NaoCam)

# include for lua headers
include_directories(../../../Lua/src)

# main library definition
add_library(NaoCam SHARED nao_cam.cc nao_cam_mmap_thread.cc cam_util.cc timeScalar.cc)

# set optimization level
#   TODO: can we now use level 2? it would not work for NaoV3
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O1")

# set library prefix to "" otherwise it will create libNaoCam.so
set_target_properties(NaoCam PROPERTIES PREFIX "")

# link to pthread and math library
target_link_libraries(NaoCam m pthread)

