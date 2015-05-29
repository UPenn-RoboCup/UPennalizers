foreach(symlink ${symlinks})
	string(REGEX REPLACE "->" ";" SRC_DEST "${symlink}")
	list(GET SRC_DEST 0 SRC)
  list(GET SRC_DEST 1 DEST) 
  #  message("${SRC} ${DEST}")
  execute_process(
    COMMAND @CMAKE_COMMAND@ -E create_symlink ${SRC} ${symdir}/${DEST} 
    OUTPUT_VARIABLE ln_out	
    RESULT_VARIABLE ln_retvel
  )
	if (NOT ${ln_retval} EQUAL 0)
		message(FATAL_ERROR "Problem when creating symbolic link from ${SRC} to ${DEST}")
	else (NOT ${ln_retval} EQUAL 0)
    message(STATUS "Creating symbolic link from ${SRC} to ${DEST}")
	endif (NOT ${ln_retval} EQUAL 0)
endforeach(symlink ${symlinks})

