CWD= $(shell pwd)

all: carray cutil unix shm 

carray::
	cd CArray && make && cd $(CWD)

cutil::
	cd CUtil && make && cd $(CWD)

unix::
	cd Unix && make && cd $(CWD)

shm::
	cd Shm && make && cd $(CWD)

primesense::
	cd PrimeSense && make && cd $(CWD)

clean::
	cd CArray && make clean && cd $(CWD)
	cd CUtil && make clean && cd $(CWD)
	cd Unix && make clean && cd $(CWD)
	cd Shm && make clean && cd $(CWD)
