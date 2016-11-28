#How to build:

mkdir build
cd build

#Cross-compile for Nao Geode:
cmake -DCMAKE_TOOLCHAIN_FILE=ctc-robocup-1.4.25.1/toolchain-geode.cmake ..

#Otherwise, normal compilation:
cmake -DCMAKE_TOOLCHAIN_FILE=aldebaran-sdk-v1.4.25.2-linux/toolchain-pc.cmake  ..

#Check of options:
ccmake .
make

In order for Lua to dynamically load modules, it needs
to be linked to /usr/local/lib/liblua.so.  There is a
hack in luafifo.cpp to dynamically open liblua.so so
that global symbols are then available to Lua modules.
On the Nao, these files need to be present:
/usr/local/lib/liblua.so

and then to easily find modules:
/usr/local/lib/lua/5.1/unix.so
/usr/local/lib/lua/5.1/kinematics.so
...
