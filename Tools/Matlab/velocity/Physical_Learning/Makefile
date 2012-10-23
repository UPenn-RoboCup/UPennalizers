INCLUDES = -I/usr/local/include -I/usr/include -I/usr/include/lua `pkg-config --cflags opencv`
LIBS = -L/usr/local/lib -L/usr/lib `pkg-config --libs opencv`

all:
	gcc -O2 `pkg-config --cflags --libs opencv` -lstdc++ -o train train.cpp csv.cpp

debug:
	gcc -g `pkg-config --cflags --libs opencv` -lstdc++ -o train train.cpp csv.cpp

clean:
	rm -f train
