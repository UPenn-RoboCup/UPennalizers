# Linux has a joystick API
#LIBNAME=joystick
# Mac does not, so we use libusb
LIBNAME=xbox360
include ../../Makefile.am
LIBOPTS+=`pkg-config libusb-1.0 --libs`
INCLUDES+=`pkg-config libusb-1.0 --cflags`
