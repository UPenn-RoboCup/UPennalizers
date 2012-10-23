cmake_minimum_required(VERSION 2.6.4 FATAL_ERROR)

project(Lua)

set(SRC_FILES lapi.c 
              lauxlib.c 
              lbaselib.c
              lcode.c
              ldblib.c
              ldebug.c
              ldo.c
              ldump.c
              lfunc.c
              lgc.c
              linit.c
              liolib.c
              llex.c
              lmathlib.c
              lmem.c
              loadlib.c
              lobject.c
              lopcodes.c
              loslib.c
              lparser.c
              lstate.c
              lstring.c
              lstrlib.c
              ltable.c
              ltablib.c
              ltm.c
              lundump.c
              lvm.c
              lzio.c
              print.c)


# lua shared library
add_library(lua SHARED ${SRC_FILES})

# lua executable
add_executable(lua-bin ${SRC_FILES} lua.c)
set_target_properties(lua-bin PROPERTIES OUTPUT_NAME lua)

# set optimization level 
set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS} -DLUA_USE_LINUX -O2 -Wall")

# link to rt for shared memory ipc
target_link_libraries(lua m dl readline history ncurses)
target_link_libraries(lua-bin m dl readline history ncurses)

