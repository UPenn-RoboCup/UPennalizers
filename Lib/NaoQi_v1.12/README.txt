# how to build

Download the naoqi atom cross compilation toolchain from aldebaran
  /path/to/ctc will be used from now on as the path to the extracted
  cross compilation toolchain

Download and install qiBuild: https://github.com/aldebaran/qibuild

# create qibuild toolchain for the nao atom
qitoolchain create cross-atom /path/to/ctc/toolchain.xml

# configure the project
qibuild configure -c cross-atom

# build the library
qibuild make -c cross-atom


*NOTE*: liblua.so MUST be present in /usr/local/lib, if you have it installed
          somewhere else you can just make a link to it in /usr/local/lib




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
