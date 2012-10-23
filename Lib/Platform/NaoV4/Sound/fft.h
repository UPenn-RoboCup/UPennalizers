#ifndef __FFT_H__
#define __FFT_H__

#include <math.h>
#include <stdio.h>

static const unsigned int NFFTMAX = 1024;
static const int SINMAX = 32768;

#ifndef PI
#define PI M_PI
#endif

/**
 * Bit reverse functions for FFT
 */
inline unsigned short bitreverse8 (unsigned short i) {
  return ((i & 0x00FF) << 8) | ((i & 0xFF00) >> 8); 
}
inline unsigned short bitreverse4 (unsigned short i) {
  return ((i & 0x0F0F) << 4) | ((i & 0xF0F0) >> 4); 
}
inline unsigned short bitreverse2 (unsigned short i) {
  return ((i & 0x3333) << 2) | ((i & 0xCCCC) >> 2); 
}
inline unsigned short bitreverse1 (unsigned short i) {
  return ((i & 0x5555) << 1) | ((i & 0xAAAA) >> 1); 
}
inline unsigned short bitreverse (unsigned short i) {
  return bitreverse1 (bitreverse2 (bitreverse4 ( bitreverse8 (i)))); 
}


/**
 * calculates the real, discrete FFT using integer arithmetic
 *
 * xr - input sound data array
 * xi - output fft data
 * n - number of FFT elements?
 * sign - +1 for fft, -1 for inverse fft
 *
 * return - 0 on success
 */
// TODO: this fails if the n is not a power of 2
int fft(int *xr, int *xi, int n, int sign = 1) {
  static int sinTable[NFFTMAX];
  static bool init = false;

  if (!init) {
    // create lookup table for possible sine values so we don't waste time
    //  repeatedly computing them
    for (int i = 0; i < NFFTMAX; i++) {
      sinTable[i] = (int)(SINMAX * sin((2*PI*(double)i) / NFFTMAX));
    }

    init = true;
  }

  // since we are using a loop up table for the sine values we cannot
  //  support signals that are longer than the predetermined max
  if (n > NFFTMAX) {
    fprintf(stderr, "fft: array size %d exceeds max %d\n", n, NFFTMAX);
    return  -1;
  }

  // this algorithm fails is n is not a power of 2
  if ((n & (n -1)) != 0) {
    fprintf(stderr, "fft: array size must be a power of 2\n", n);
    return -1;
  }

  // Calculate m such that n = 2^m
  int m;
  if (frexp(n, &m) != 1.0) {
    m -= 1;
  }

  int n2 = n;
  for (int k = 0; k < m; k++) {
    int n1 = n2;
    n2 >>= 1;

    for (int j = 0; j < n2; j++) {
      // Look up sin and cos for a = 2*PI * j / n1
      int iTable = NFFTMAX * j / n1;
      int s = sign * sinTable[iTable % NFFTMAX];
      int c = sinTable[(iTable + (NFFTMAX/4)) % NFFTMAX];

      for (int i = j; i < n; i += n1) {
        int q = i + n2;

        int tempr = xr[i] - xr[q];
        xr[i] += xr[q];
        int tempi = xi[i] - xi[q];
        xi[i] += xi[q];

        // Divide by 2 at each stage to prevent overflows
        // but results in loss of resolution by m bits
        tempr >>= 1;
        xr[i] >>= 1;
        tempi >>= 1;
        xi[i] >>= 1;

        xr[q] = (c*tempr + s*tempi)/SINMAX;
        xi[q] = (c*tempi - s*tempr)/SINMAX;
      }
    }    

    /*
    for (int kk = 0; kk < n; kk++) {
      printf("Stage %d, x[%d] = %d + i %d\n", k, kk, xr[kk], xi[kk]);
    }
    */
  }

  // bit reversed indexing
  for (int i = 0; i < n; i++) {
    int j = bitreverse(i) >> (8*sizeof(unsigned short) - m);
    if (j > i) {
      // swap xr[i] with xr[j]
      int tempr = xr[j]; 
      xr[j] = xr[i]; 
      xr[i] = tempr;

      // swap xi[i] with xi[j]
      int tempi = xi[j]; 
      xi[j] = xi[i]; 
      xi[i] = tempi;
    }
  }

  return 0;
}

#endif

