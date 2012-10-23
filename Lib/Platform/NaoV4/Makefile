CWD= $(shell pwd)

all:
	cd Body && make && cd $(CWD)
	cd Camera && make && cd $(CWD)
	cd GameControl && make && cd $(CWD)
	cd Kinematics && make && cd $(CWD)
	cd Sound && make && cd $(CWD)

clean:
	cd Body && make clean && cd $(CWD)
	cd Camera && make clean && cd $(CWD)
	cd Kinematics && make clean && cd $(CWD)
	cd GameControl && make clean && cd $(CWD)
	cd Sound && make clean && cd $(CWD)

