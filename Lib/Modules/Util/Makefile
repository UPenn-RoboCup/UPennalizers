CWD= $(shell pwd)

ifeq ($(CTCDIR),)
  ifeq ($(CROSS),true)
    CTCDIR= $(NaoqiCTC)
  endif
endif

export CTCDIR

all: carray cutil unix shm zlib llthreads

carray::
	cd CArray && make && cd $(CWD)

cutil::
	cd CUtil && make && cd $(CWD)

unix::
	cd Unix && make && cd $(CWD)

shm::
	cd Shm && make && cd $(CWD)

zlib::
	cd Z && make && cd $(CWD)

llthreads::
	cd llthreads && make && cd $(CWD)

clean::
	cd CArray && make clean && cd $(CWD)
	cd CUtil && make clean && cd $(CWD)
	cd Unix && make clean && cd $(CWD)
	cd Shm && make clean && cd $(CWD)
	cd Z && make clean && cd $(CWD)
	cd llthreads && make clean && cd $(CWD)
