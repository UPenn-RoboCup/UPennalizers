cmake_minimum_required( VERSION 2.8.0 )
project( Upennalizer-lib )

include_directories(AFTER SYSTEM ./)
include_directories(AFTER SYSTEM /usr/local/include/)
include_directories(AFTER SYSTEM /usr/include/)
include_directories(AFTER SYSTEM /home/nao/naoSDK/include/)


SET(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/Lib)

add_subdirectory(./Modules/Comm/)
add_subdirectory(./Modules/ImageProc/)
add_subdirectory(./Modules/Util/CArray/)
add_subdirectory(./Modules/Util/CUtil/)
add_subdirectory(./Modules/Util/llthreads/)
add_subdirectory(./Modules/Util/Shm/)
add_subdirectory(./Modules/Util/Unix/)
add_subdirectory(./Modules/Util/Z/)


#Add NaoV4 libraries
add_subdirectory(./Platform/NaoV4/GameControl/)
add_subdirectory(./Platform/NaoV4/Kinematics/)

add_subdirectory(./Platform/NaoV4/TeamComm/)

if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
	add_subdirectory(./Platform/NaoV4/NaoQiV4/)
	add_subdirectory(./Platform/NaoV4/NaoQiV5/)
endif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
