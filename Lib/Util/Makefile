CWD= $(shell pwd)

all: carray cutil unix shm

carray::
	cd CArray && MODE=$(MODE) make && cd $(CWD)

cutil::
	cd CUtil && MODE=$(MODE) make && cd $(CWD)

unix::
	cd Unix && MODE=$(MODE) make && cd $(CWD)

shm::
	cd Shm && MODE=$(MODE) make && cd $(CWD)

clean::
	cd CArray && make clean && cd $(CWD)
	cd Unix && make clean && cd $(CWD)
	cd Shm && make clean && cd $(CWD)

