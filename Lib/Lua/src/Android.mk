#include $(call all-subdir-makefiles)

LOCAL_PATH := $(call my-dir)
NDK_PATH := /home/brindza/upenn/android/android-ndk-r7

# Core Lua library
# compiled as static library to embed in liblua-activity.so
include $(CLEAR_VARS)
LOCAL_MODULE := luacore
LOCAL_SRC_FILES := lua/lapi.c \
	lua/lauxlib.c \
	lua/lbaselib.c \
	lua/lcode.c \
	lua/ldblib.c \
	lua/ldebug.c \
	lua/ldo.c \
	lua/ldump.c \
	lua/lfunc.c \
	lua/lgc.c \
	lua/linit.c \
	lua/liolib.c \
	lua/llex.c \
	lua/lmathlib.c \
	lua/lmem.c \
	lua/loadlib.c \
	lua/lobject.c \
	lua/lopcodes.c \
	lua/loslib.c \
	lua/lparser.c \
	lua/lstate.c \
	lua/lstring.c \
	lua/lstrlib.c \
	lua/ltable.c \
	lua/ltablib.c \
	lua/ltm.c \
	lua/lundump.c \
	lua/lvm.c \
	lua/lzio.c \
	lua/print.c

# Auxiliary lua user defined file
#	lua/luauser.c
#LOCAL_CFLAGS := -DLUA_DL_DLOPEN -DLUA_USER_H='"luauser.h"'

LOCAL_C_INCLUDES := $(LOCAL_PATH)/lua
LOCAL_CFLAGS := -DLUA_DL_DLOPEN
LOCAL_LDLIBS := -ldl -llog
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/lua
include $(BUILD_STATIC_LIBRARY)

# Native main activity library
# Note: Android runtime loader is very limited
# Native activity library cannot dlopen any custom shared libraries
# Need to statically link lua and asset module here
include $(CLEAR_VARS)
LOCAL_MODULE    := lua-activity
LOCAL_SRC_FILES := activity.cpp
# Statically compile in jnicontext:
LOCAL_SRC_FILES += jnicontext.cpp
LOCAL_LDLIBS    := -llog -landroid -ldl
LOCAL_STATIC_LIBRARIES := luacore
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/lua
include $(BUILD_SHARED_LIBRARY)


# Now can build custom lua modules by linking to liblua-activity.so

# Need to build as libsocket_core.so
# since Android libs directory cannot have subdirectories
# and because all-in-one loader loads before Android asset loader
include $(CLEAR_VARS)
LOCAL_MODULE := socket_core
LOCAL_SRC_FILES := \
	modules/socket/luasocket.c \
	modules/socket/timeout.c \
	modules/socket/buffer.c \
	modules/socket/io.c \
	modules/socket/auxiliar.c \
	modules/socket/options.c \
	modules/socket/inet.c \
	modules/socket/tcp.c \
	modules/socket/udp.c \
	modules/socket/except.c \
	modules/socket/select.c \
	modules/socket/usocket.c
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# lua socket mime.core module (all-in-one loader should open libmime.so)
include $(CLEAR_VARS)
LOCAL_MODULE := mime_core
LOCAL_SRC_FILES := modules/socket/mime.c
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# lua lanes core module
include $(CLEAR_VARS)
LOCAL_MODULE := lua51-lanes
LOCAL_SRC_FILES := \
	modules/lanes/lanes.c \
	modules/lanes/threading.c \
	modules/lanes/tools.c \
	modules/lanes/keeper.c \
	modules/lanes/pthread_hack.c
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# unix module to access Unix library functions
include $(CLEAR_VARS)
LOCAL_MODULE := unix
LOCAL_SRC_FILES := modules/unix/luaunix.c
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# carray module to manipulate C arrays in lua
include $(CLEAR_VARS)
LOCAL_MODULE := carray
LOCAL_SRC_FILES := modules/carray/luacarray.cpp
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# pthread module to start POSIX lua threads
include $(CLEAR_VARS)
LOCAL_MODULE := pthread
LOCAL_SRC_FILES := modules/pthread/luapthread.cpp
LOCAL_SHARED_LIBRARIES := lua-activity
LOCAL_C_INCLUDES += $(NDK_PATH)/sources/cxx-stl/stlport/stlport
LOCAL_LDLIBS += -L$(NDK_PATH)/sources/cxx-stl/stlport/libs/armeabi -lstlport_static
include $(BUILD_SHARED_LIBRARY)

# OpenGL ES module
include $(CLEAR_VARS)
LOCAL_MODULE := gles
LOCAL_LDLIBS := -landroid -llog -lGLESv1_CM
#LOCAL_LDLIBS += -lEGL -lGLESv1_CM
LOCAL_SRC_FILES := modules/gles/luagles.cpp
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# OpenGL EGL module
include $(CLEAR_VARS)
LOCAL_MODULE := egl
LOCAL_LDLIBS := -landroid -llog -lEGL
LOCAL_SRC_FILES := modules/egl/luaegl.c
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# FTGL module for OpenGL text
include $(CLEAR_VARS)
LOCAL_MODULE := ftgl
LOCAL_SRC_FILES := modules/ftgl/luaftgl.c
LOCAL_C_INCLUDES += $(LOCAL_PATH)/include
LOCAL_LDFLAGS += -L$(LOCAL_PATH)/lib/armeabi
LOCAL_LDLIBS := -lftgles-static -lglu-static -lfreetype2-static -lGLESv1_CM
LOCAL_LDLIBS += -L$(NDK_PATH)/sources/cxx-stl/stlport/libs/armeabi -lstlport_static
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

#
# Android specific modules:
#

# asset module to access Android package assets
include $(CLEAR_VARS)
LOCAL_MODULE := asset
LOCAL_LDLIBS := -landroid -llog
LOCAL_SRC_FILES := modules/asset/luaasset.cpp
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# sensor module to access Android sensor (accel, mag, gyr, etc.)
include $(CLEAR_VARS)
LOCAL_MODULE := sensor
LOCAL_LDLIBS := -landroid -llog
LOCAL_SRC_FILES := modules/sensor/luasensor.cpp
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# vibrator module to access Android vibrator
include $(CLEAR_VARS)
LOCAL_MODULE := vibrator
LOCAL_LDLIBS := -landroid -llog
LOCAL_SRC_FILES := modules/vibrator/luavibrator.cpp
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# toast module to show Android toast messages
include $(CLEAR_VARS)
LOCAL_MODULE := toast
LOCAL_LDLIBS := -landroid -llog
LOCAL_SRC_FILES := modules/toast/luatoast.cpp
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# inputevent modules to query Android Input Events
include $(CLEAR_VARS)
LOCAL_MODULE := inputevent
LOCAL_LDLIBS := -landroid -llog
LOCAL_SRC_FILES := modules/inputevent/luainputevent.cpp
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# native camera module to access Android camera
include $(CLEAR_VARS)
LOCAL_MODULE := nativecamera
LOCAL_SRC_FILES := modules/camera/luanativecamera.cpp
LOCAL_C_INCLUDES += $(LOCAL_PATH)/android/include
LOCAL_LDFLAGS += -L$(LOCAL_PATH)/android/lib
LOCAL_LDLIBS := -lcamera_client -lutils -lbinder -llog
LOCAL_STATIC_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# TTS module for Android text to speech
include $(CLEAR_VARS)
LOCAL_MODULE := tts
LOCAL_LDLIBS := -landroid -llog
LOCAL_SRC_FILES := modules/tts/luatts.cpp
LOCAL_SHARED_LIBRARIES := lua-activity
include $(BUILD_SHARED_LIBRARY)

# c utility functions
include $(CLEAR_VARS)
LOCAL_MODULE := cutil
LOCAL_LDLIBS := -landroid -llog
LOCAL_SRC_FILES := modules/cutil/luacutil.cpp
LOCAL_SHARED_LIBRARIES := lua-activity
LOCAL_C_INCLUDES += $(NDK_PATH)/sources/cxx-stl/stlport/stlport
LOCAL_LDLIBS += -L$(NDK_PATH)/sources/cxx-stl/stlport/libs/armeabi -lstlport_static
include $(BUILD_SHARED_LIBRARY)

# c utility functions
include $(CLEAR_VARS)
LOCAL_MODULE := usb
LOCAL_LDLIBS := -landroid -llog
LOCAL_SRC_FILES := modules/usb/luausb.cpp 
LOCAL_SHARED_LIBRARIES := lua-activity
LOCAL_C_INCLUDES += $(NDK_PATH)/sources/cxx-stl/stlport/stlport
LOCAL_LDLIBS += -L$(NDK_PATH)/sources/cxx-stl/stlport/libs/armeabi -lstlport_static
include $(BUILD_SHARED_LIBRARY)


# image processing library
include $(CLEAR_VARS)
LOCAL_MODULE := ImageProc 
LOCAL_LDLIBS := -landroid -llog
LOCAL_SRC_FILES := modules/image/luaImageProc.cpp \
										modules/image/timeScalar.cpp 
LOCAL_SHARED_LIBRARIES := lua-activity
LOCAL_CPPFLAGS := -O3
LOCAL_CFLAGS := -O3
LOCAL_C_INCLUDES += $(NDK_PATH)/sources/cxx-stl/stlport/stlport
LOCAL_LDLIBS += -L$(NDK_PATH)/sources/cxx-stl/stlport/libs/armeabi -lstlport_static
include $(BUILD_SHARED_LIBRARY)

# module for Android shm
include $(CLEAR_VARS)
LOCAL_MODULE := shm
LOCAL_LDLIBS := -landroid -llog
LOCAL_SRC_FILES := modules/shm/luashm.cpp modules/shm/android_shm.cpp
LOCAL_C_INCLUDES += $(LOCAL_PATH)/include $(LOCAL_PATH)/modules/shm/include/
LOCAL_SHARED_LIBRARIES := lua-activity

# boost flags
LOCAL_CPPFLAGS += -DBOOST_INTERPROCESS_XSI_SHARED_MEMORY_OBJECTS_ONLY
LOCAL_CPPFLAGS += -DBOOST_ANDROID_SHARED_MEMORY

#stlport
##LOCAL_C_INCLUDES += $(NDK_PATH)/sources/cxx-stl/stlport/stlport
##LOCAL_LDLIBS += -L$(NDK_PATH)/sources/cxx-stl/stlport/libs/armeabi -lstlport_static
LOCAL_C_INCLUDES += $(NDK_PATH)/sources/cxx-stl/gnu-libstdc++/include
LOCAL_C_INCLUDES += $(NDK_PATH)/sources/cxx-stl/gnu-libstdc++/libs/armeabi/include
LOCAL_LDLIBS += -L$(NDK_PATH)/sources/cxx-stl/gnu-libstdc++/libs/armeabi -lgnustl_static
LOCAL_CPPFLAGS += -fexceptions -frtti
include $(BUILD_SHARED_LIBRARY)
