/*
  RadonTransform class
  Written by Daniel D. Lee, 06/2009
  <ddlee@seas.upenn.edu>
*/

#include "RadonTransform.h"
#include <stdlib.h>
#include <limits.h>
#include <math.h>

#ifndef PI
#define PI M_PI
#endif

RadonTransform::RadonTransform() {
  // Initialize trigonometry tables:
  for (int i = 0; i < NTH; i++) {
    th[i] = 2*PI*i/NTH;
    cosTable[i] = NTRIG*cos(th[i]);
    sinTable[i] = NTRIG*sin(th[i]);
  }

  clear();
}

void RadonTransform::clear() {
  countMax = 0;
  for (int ith = 0; ith < NTH; ith++) {
    for (int ir = 0; ir < NR; ir++) {
      count[ith][ir] = 0;

      lineMin[ith][ir] = INT_MAX;
      lineMax[ith][ir] = INT_MIN;
      lineSum[ith][ir] = 0;
    }
  }
}

void RadonTransform::addPixelToRay(int i, int j, int ith) {
  int ir = (cosTable[ith]*i + sinTable[ith]*j)/NTRIG;
  if (ir >= 0) {
    count[ith][ir]++;
    if (count[ith][ir] > countMax) {
      thMax = ith;
      rMax = ir;
      countMax = count[ith][ir];
    }

    // Line statistics:
    int iline = (-sinTable[ith]*i + cosTable[ith]*j)/NTRIG;
    lineSum[ith][ir] += iline;
    if (iline > lineMax[ith][ir]) lineMax[ith][ir] = iline;
    if (iline < lineMin[ith][ir]) lineMin[ith][ir] = iline;    
  }
}

void RadonTransform::addHorizontalPixel(int i, int j) {
  for (int ith = 0; ith < NTH; ith++) {
    if (abs(sinTable[ith]) < DIAGONAL_THRESHOLD)
      continue;
    addPixelToRay(i, j, ith);
  }
}

void RadonTransform::addVerticalPixel(int i, int j) {
  for (int ith = 0; ith < NTH; ith++) {
    if (abs(cosTable[ith]) < DIAGONAL_THRESHOLD)
      continue;
    addPixelToRay(i, j, ith);
  }
}

struct LineStats &RadonTransform::getLineStats() {
  bestLine.count = countMax;
  if (countMax == 0) return bestLine;

  double iR = (rMax+.5)*cosTable[thMax];
  double jR = (rMax+.5)*sinTable[thMax];
  double lMean = lineSum[thMax][rMax]/countMax;
  double lMin = lineMin[thMax][rMax];
  double lMax = lineMax[thMax][rMax];

  bestLine.iMean = (iR - lMean*sinTable[thMax])/NTRIG;
  bestLine.jMean = (jR + lMean*cosTable[thMax])/NTRIG;
  bestLine.iMin = (iR - lMin*sinTable[thMax])/NTRIG;
  bestLine.jMin = (jR + lMin*cosTable[thMax])/NTRIG;
  bestLine.iMax = (iR - lMax*sinTable[thMax])/NTRIG;
  bestLine.jMax = (jR + lMax*cosTable[thMax])/NTRIG;
  return bestLine;
}
