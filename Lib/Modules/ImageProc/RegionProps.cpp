#include "RegionProps.h"
#include <limits.h>

RegionProps::RegionProps() :
  area(0),
  minI(INT_MAX), maxI(INT_MIN),
  minJ(INT_MAX), maxJ(INT_MIN),
  sumI(0), sumJ(0)
{ }

void RegionProps::clear() {
  area = 0;
  minI = INT_MAX;
  maxI = INT_MIN;
  minJ = INT_MAX;
  maxJ = INT_MIN;
  sumI = 0;
  sumJ = 0;
}

void RegionProps::add(int i, int j) {
  area++;
  if (i < minI) minI = i;
  if (i > maxI) maxI = i;
  if (j < minJ) minJ = j;
  if (j > maxJ) maxJ = j;
  sumI += i;
  sumJ += j;
}

// Reverse < for sorting algorithm:
bool operator< (const RegionProps& a, const RegionProps &b) {
  return a.area > b.area;
}
