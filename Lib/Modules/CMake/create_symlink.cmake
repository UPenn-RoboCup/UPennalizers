if (NOT DEFINED SYMLINKS) 
  message("ddd")
endif(NOT DEFINED SYMLINKS)
#set(SYM_LINKS @SYMLINKS@)
#
#if (NOT DEFINED SYM_LINKS)
#      message(FATAL_ERROR "Required SYM_LINKS undefined")
#endif(NOT DEFINED SYM_LINKS)
#
##string(REGEX REPLACE "\n" ";" SYM_LINKS "${SYM_LINK}")
#
#foreach (SYM_LINK ${SYMLINKS})
#  message("${SYM_LINK}")
#	string(REGEX REPLACE "->" ";" SRC_DEST "${SYM_LINK}")
#	list(GET SRC_DEST 0 SRC)
#	list(GET SRC_DEST 1 DEST) 
##	message("${SRC} ${DEST}")
#	execute_process(
#		COMMAND @CMAKE_COMMAND@ -E create_symlink ${SRC} ${DEST} 
#		OUTPUT_VARIABLE ln_out
#		RESULT_VARIABLE ln_retvel
#	)
#	if (NOT ${ln_retval} EQUAL 0)
#		message(FATAL_ERROR "Problem when creating symbolic link from ${SRC} to ${DEST}")
#	else (NOT ${ln_retval} EQUAL 0)
#	  	message(STATUS "Creating link from ${SRC} to ${DEST}")
#	endif (NOT ${ln_retval} EQUAL 0)
#endforeach(SYM_LINK)
