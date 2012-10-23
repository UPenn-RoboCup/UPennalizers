g++ -O1 -fpic -I/usr/local/include -I/usr/include/lua5.1 -lrt -I/usr/local/include/boost -o naoCam.o -c naoCam.cc
g++ -O1 -fpic -I/usr/local/include -I/usr/include/lua5.1 -lrt -I/usr/local/include/boost -o naoCamThread.o -c naoCamThread.cc
g++ -O1 -fpic -I/usr/local/include -I/usr/include/lua5.1 -lrt -I/usr/local/include/boost -o timeScalar.o -c timeScalar.cc
#g++ -O1 -fpic -I/usr/local/include -I/usr/include/lua5.1 -lrt -I/usr/local/include/boost -o i2cBus.o -c i2cBus.cc
g++  -lrt -I/usr/local/include/boost -o NaoCam.so -shared naoCam.o naoCamThread.o timeScalar.o -L/usr/local/lib -lm -lpthread
