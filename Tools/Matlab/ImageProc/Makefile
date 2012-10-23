# Makefile used to build mex files

TARGETS = all clean
.PHONY: $(TARGETS)

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
  #export OSTYPE
endif

ifeq ($(OSTYPE),linux)
  MEXSUFFIX = mexglx
endif
ifeq ($(OSTYPE),darwin)
  MEXSUFFIX = mexmaci64
endif

MEX = mex
CXXFLAGS = -O

all: yuyv2label.$(MEXSUFFIX) \
	block_bitor.$(MEXSUFFIX) \
	color_count.$(MEXSUFFIX) \
	color_stats.$(MEXSUFFIX) \
	connected_regions.$(MEXSUFFIX) \
	goal_posts.$(MEXSUFFIX) \
	field_lines.$(MEXSUFFIX) \
	field_occupancy.$(MEXSUFFIX) \
	field_spots.$(MEXSUFFIX)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -fPIC -o $@ -c $<
%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -fPIC -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(INCLUDE_DIRS) -fPIC -o $@ -c $<

%.$(MEXSUFFIX): %.cc
	$(MEX) $(CXXFLAGS) $<

connected_regions.$(MEXSUFFIX): connected_regions.cc RegionProps.o ConnectRegions.o
	$(MEX) $(CXXFLAGS) $^

goal_posts.$(MEXSUFFIX): goal_posts.cc RegionProps.o
	$(MEX) $(CXXFLAGS) $^

goal_crossbar.$(MEXSUFFIX): goal_crossbar.cc RegionProps.o
	$(MEX) $(CXXFLAGS) $^

field_lines.$(MEXSUFFIX): field_lines.cc RadonTransform.o
	$(MEX) $(CXXFLAGS) $^

field_spots.$(MEXSUFFIX): field_spots.cc RegionProps.o ConnectRegions.o
	$(MEX) $(CXXFLAGS) $^

clean:
	rm -f *.$(MEXSUFFIX) *.o
