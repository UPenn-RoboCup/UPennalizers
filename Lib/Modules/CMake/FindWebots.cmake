# - Find Webots 
# Find the webots installation dir, make the user available to specify one location
#
# WEBOTS_INCLUDE_C_DIR         - where to find header for c/c++ developement of controller/supervisor
# WEBOTS_INCLUDE_CPP_DIR         - where to find header for c/c++ developement of controller/supervisor
# WEBOTS_INCLUDE_PLUGINS_DIR   - where to find headers for webots plugins devellopement
# WEBOTS_TEMPLATE_DIR          - where to find template file like controllers/Makefile.amlude and plugins/physics/physics.c
# WEBOTS_LIBRARIES             - List of libraries to link against, full path
# WEBOTS_HOME_DIR              - WEBOTS_HOME
# WEBOTS_CXXFLAGS              - COMPILE_FLAGS to use for Webots Controller
# WEBOTS_CXXFLAGS_PHYSICS      - COMPILE_FLAGS to use for physics plugins
# WEBOTS_VERSION               - Webots version number
# WEBOTS_EXE                   - Webots executable (full path)
# WEBOTS_FOUND                 - TRUE if webots found 
#
#
# Created on : 4 jum. 2010
# author : Alexandre Tuleu
# Copyright 2010 EPFL Ecole Polytechnique Federale de Lausanne
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

################################################################################
# Windows compilation of libCppController
################################################################################
macro(compile_libCppController LIBRARY_CPP HOME)
    #get all files to compile
    file(GLOB CPP_CONTROLLER_SOURCES ${HOME}/projects/packages/cpp/src/*.cpp)  
    add_library(CppController STATIC ${CPP_CONTROLLER_SOURCES})

    if(MSVC)# special flags for MSVC
      # WARNING : Don't forget "" as Windows paths can contains some spaces ....
      set_target_properties(CppController PROPERTIES COMPILE_FLAGS "/I\"${WEBOTS_INCLUDE_C_DIR}\" /I\"${WEBOTS_INCLUDE_CPP_DIR}\"")
    else(MSVC)# min-gw ? 
      set_target_properties(CppController PROPERTIES COMPILE_FLAGS "-I\"${WEBOTS_INCLUDE_C_DIR}\" -I\"${WEBOTS_INCLUDE_CPP_DIR}\"")
    endif(MSVC)
    #set the dependancy
    set(${LIBRARY_CPP} CppController)
endmacro(compile_libCppController)


################################################################################
# MACRO FOR GETTING VERSION == OS DEPENDANT ==
################################################################################
macro(get_version_linux VERSION)
	execute_process(COMMAND ${WEBOTS_EXE} "--version" 
                                OUTPUT_VARIABLE VERSION_TMP
	                        OUTPUT_STRIP_TRAILING_WHITESPACE)
	if(NOT VERSION_TMP)
		set(VERSION_TMP "version 0.0.0")
	endif(NOT VERSION_TMP)
	string(REGEX REPLACE ".*([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.*" 
	                     "\\1.\\2.\\3" 
	                     ${VERSION} 
	                     ${VERSION_TMP})
endmacro(get_version_linux)

macro(get_version_osx VERSION HOME)
	file(READ ${HOME}/webots.app/Contents/Info.plist PLIST)

	string(REGEX REPLACE ".*CFBundleShortVersionString.*<string>([0-9]+)\\.([0-9]+)\\.([0-9]+)</string>.*" 
		     	     "\\1.\\2.\\3" 
			     ${VERSION} 
			     ${PLIST})


endmacro(get_version_osx)

macro(get_version_windows VERSION HOME)
	set(CHANGE_LOG_FILE "${HOME}/doc/guide/guide.html")
	message(STATUS "${CHANGE_LOG_FILE}")
#	if(EXISTS CHANGE_LOG_FILE)
		file(READ ${HOME}/doc/ChangeLog.html CHANGE_LOG)
		string(REGEX MATCH "([0-9]+)\\.([0-9]+)\\.([0-9]+)"
				   ${VERSION}
			     	   ${CHANGE_LOG})
#	else(EXISTS CHANGE_LOG_FILE)
#		set(${VERSION} "5.10.0")
#	endif(EXISTS CHANGE_LOG_FILE)
endmacro(get_version_windows)

################################################################################
# MACRO THAT GET EVERY VALUE
################################################################################
# Take the target home as paremeter WEBOTS_HOME

macro(find_webots_with_home WEBOTS_HOME)

# Get all the headers			   			 
  find_path(WEBOTS_INCLUDE_CPP_DIR webots/Supervisor.hpp PATHS ${WEBOTS_HOME}/include/controller/cpp)
  find_path(WEBOTS_INCLUDE_C_DIR webots/supervisor.h PATHS ${WEBOTS_HOME}/include/controller/c)
  find_path(WEBOTS_INCLUDE_PLUGINS_DIR plugins/physics.h PATHS ${WEBOTS_HOME}/include)
  find_path(WEBOTS_TEMPLATE_DIR controllers/Makefile.amlude PATHS ${WEBOTS_HOME}/resources ${WEBOTS_HOME}/projects/default )

set(SEARCH_OPTIONS "NO_DEFAULT_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_PATH NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH")
#get the Libraries
  find_library(WEBOTS_LIBRARY_CPP CppController PATHS ${WEBOTS_HOME}/lib 
                                  ${SEARCH_OPTIONS})
  find_library(WEBOTS_LIBRARY_C Controller PATHS ${WEBOTS_HOME}/lib 
                                ${SEARCH_OPTIONS})
#Hehe we did not found the library libCpp, so we might use msvc. 
  if(WIN32 AND NOT WEBOTS_LIBRARY_CPP) 
  # There is no libCppController for msvc, so we need to compile it and make 
  # this target available for cmake
     compile_libCppController(WEBOTS_LIBRARY_CPP ${WEBOTS_HOME})
  endif(WIN32 AND NOT WEBOTS_LIBRARY_CPP) 

  if(WEBOTS_LIBRARY_CPP AND WEBOTS_LIBRARY_C)

    list(APPEND WEBOTS_LIBRARIES ${WEBOTS_LIBRARY_CPP} ${WEBOTS_LIBRARY_C})
    set(WEBOTS_HOME_DIR ${WEBOTS_HOME})
  else(WEBOTS_LIBRARY_CPP AND WEBOTS_LIBRARY_C)
    set(WEBOTS_LIBRARIES ) 
  endif(WEBOTS_LIBRARY_CPP AND WEBOTS_LIBRARY_C)
  find_program(WEBOTS_EXE webots NAMES webots PATHS ${WEBOTS_HOME} NO_DEFAULT_PATH )

  if(WEBOTS_EXE)
    if(APPLE)
      get_version_osx(WEBOTS_VERSION ${WEBOTS_HOME})
    elseif(WIN32)
      get_version_windows(WEBOTS_VERSION ${WEBOTS_HOME})
    else(APPLE)
      get_version_linux(WEBOTS_VERSION)
    endif(APPLE)
  endif(WEBOTS_EXE)

endmacro(find_webots_with_home)

if(WEBOTS_LIBRARIES)
  #already in cache, be silent
  set(WEBOTS_FIND_QUIETLY TRUE)
endif(WEBOTS_LIBRARIES)


#Here we need to define an intermediary variable as $ENV{WEBOTS_HOME} is 
#directly its value, not a variable (and ENV{WEBOTS_HOME} is not defined)
#also for WIN32, we need to convert the path
set(IS_ENV_WEBOTS_HOME $ENV{WEBOTS_HOME})

if(IS_ENV_WEBOTS_HOME)
  message(STATUS "Using user-specified installation of webots : ${IS_ENV_WEBOTS_HOME}")
  file(TO_CMAKE_PATH "$ENV{WEBOTS_HOME}" IS_ENV_WEBOTS_HOME)

  find_webots_with_home(${IS_ENV_WEBOTS_HOME})
else(IS_ENV_WEBOTS_HOME)
  message(STATUS "Warning, you did not define your WEBOTS_HOME environnement variable, try to find it by ourselve, but your installation may not work properly !")
  if(APPLE)
    find_webots_with_home(/Applications/Webots)
  else(APPLE)  
    if(UNIX)
      find_webots_with_home(/usr/local/webots)
    endif(UNIX)
  endif(APPLE)


  if(WIN32)
    find_webots_with_home("C:/Program\\ files/Webots")
  endif(WIN32)

endif(IS_ENV_WEBOTS_HOME)



#find_file(GL_HEADER_FOUND GL/gl.h)
#
#if(GL_HEADER_FOUND)
#    message(STATUS "Found OpenGL headers : ${GL_HEADER_FOUND}")
#else(GL_HEADER_FOUND)
#    message(STATUS "Did not found OpenGL headers, your installation of webots may not work properly.")
#endif(GL_HEADER_FOUND)



include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(WEBOTS DEFAULT_MSG WEBOTS_EXE WEBOTS_LIBRARIES 
                                  WEBOTS_INCLUDE_CPP_DIR WEBOTS_INCLUDE_C_DIR 
                                  WEBOTS_INCLUDE_PLUGINS_DIR WEBOTS_HOME_DIR
                                  WEBOTS_VERSION GL_HEADER_FOUND WEBOTS_TEMPLATE_DIR)

if(WEBOTS_FOUND)
  if(APPLE)#force the 32 bits compiation on OS X
    set(WEBOTS_CXXFLAGS "-march=i386 -m32 -DMACOS")
    set(WEBOTS_LDFLAGS "-march=i386")
  else(APPLE)
    set(WEBOTS_CXXFLAGS " ")
  endif(APPLE)
  mark_as_advanced(WEBOTS_LIBRARIES WEBOTS_INCLUDE_CPP_DIR WEBOTS_INCLUDE_C_DIR
                   WEBOTS_INCLUDE_PLUGINS_DIR WEBOTS_HOME_DIR WEBOTS_LIBRARY_C 
                   WEBOTS_LIBRARY_CPP WEBOTS_CXXFLAGS WEBOTS_EXE WEBOTS_VERSION
                   GL_HEADER_FOUND WEBOTS_TEMPLATE_DIR)
endif(WEBOTS_FOUND)
