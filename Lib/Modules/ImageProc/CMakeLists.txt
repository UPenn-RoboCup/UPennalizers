cmake_minimum_required( VERSION 2.8.0 )
project( ImageProcFuncs )

include_directories(AFTER SYSTEM ./)
include_directories(AFTER SYSTEM /usr/local/include/)
include_directories(AFTER SYSTEM /usr/include/)
include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)

set( ImageProcFuncs_srcs 
  color_count.cpp
  block_bitor.cpp
  ConnectRegions.cpp
  RegionProps.cpp
  RadonTransform.cpp
  lua_color_stats.cpp
  lua_color_count.cpp 
  lua_colorlut_gen.cpp
  lua_connect_regions.cpp
  lua_goal_posts_white.cpp
  lua_goal_posts.cpp
  lua_robots.cpp
  lua_field_lines.cpp
  lua_field_spots.cpp
  lua_field_occupancy.cpp
)

add_library(
  ImageProcFuncs
  SHARED
  ${ImageProcFuncs_srcs} )


set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set_target_properties(ImageProcFuncs
                      PROPERTIES PREFIX  ""
                      SUFFIX ".so")

target_link_libraries(ImageProcFuncs -lm)
target_link_libraries(ImageProcFuncs -llua)
