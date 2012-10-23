cmake_minimum_required(VERSION 2.6.4 FATAL_ERROR)

project(ImageProc)

# include for lua headers
include_directories(../../Lua/src)

# ImageProc main library definition
add_library(ImageProc SHARED 
              block_bitor.cpp
              color_count.cpp
              ConnectRegions.cpp
              lua_robots.cpp
              lua_color_stats.cpp
              lua_field_lines.cpp
              lua_field_occupancy.cpp
              lua_field_spots.cpp
              lua_goal_posts.cpp
              luaImageProc.cpp
              RadonTransform.cpp
              RegionProps.cpp)

# set optimization level
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

# set library prefix to "" otherwise it will create libImageProc.so
set_target_properties(ImageProc PROPERTIES PREFIX "")

# link to math library 
target_link_libraries(ImageProc m)

