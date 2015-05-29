# Makefile used to build Webots files
include ../../../Makefile.am

all: unix stty getch signal invhyp

unix: luaunix.o
	@echo "\t" LINK $@
	@$(LD) $(LDFLAGS) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ $(LIB_DIR) -lm $(LIBRT) $(LUA_LIB)

invhyp: lua_invhyp.o
	@echo "\t" LINK $@
	@$(LD) $(LDFLAGS) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ $(LIB_DIR) -lm $(LIBRT) $(LUA_LIB)

stty: luastty.o
	@echo "\t" LINK $@
	@$(LD) $(LDFLAGS) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ $(LIB_DIR)

getch: lua_getch.o
	@echo "\t" LINK $@
	@$(LD) $(LDFLAGS) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ $(LIB_DIR) -lm $(LUA_LIB)

serial: luaserial.o
	@echo "\t" LINK $@
	@$(LD) $(LDFLAGS) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ $(LIB_DIR)

signal: lua_signal.o
	@echo "\t" LINK $@
	@$(LD) $(LDFLAGS) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ $(LIB_DIR)

clean:
	rm -f *.o *.$(SHLIBEXT)
