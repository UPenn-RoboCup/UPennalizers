#include <vector>
#include <math.h>
#include <stdint.h>

#include "block_bitor.h"

uint8_t *block_bitor(uint8_t *x, int mx, int nx, int msub, int nsub) {
  static std::vector<uint8_t> block;

  int my = 1+(mx-1)/msub;
  int ny = 1+(nx-1)/nsub;

  block.resize(my*ny);
  for (int iy = 0; iy < my*ny; iy++) {
    block[iy] = 0;
  }
  
  for (int jx = 0; jx < nx; jx++) {
    int jy = jx/nsub;

    for (int ix = 0; ix < mx; ix++) {
      int iy = ix/msub;
      block[iy+jy*my] |= *x++;
    }
  }

  return &block[0];
}

uint8_t *block_bitor_obs(uint8_t *x, int mx, int nx, int msub, int nsub) {
  static std::vector<uint8_t> block;

  int my = 1+(mx-1)/msub;
  int ny = 1+(nx-1)/nsub;

  block.resize(my*ny);
  for (int iy = 0; iy < my*ny; iy++) {
    block[iy] = 0;
  }
  
  for (int jx = 0; jx < nx; jx++) {
    int jy = jx/nsub;

    for (int ix = 0; ix < mx; ix++) {
      int iy = ix/msub;
      block[iy+jy*my] |= *x++;
    }
  }

  return &block[0];
}

//Tilted bitor function
//Makes a bitor image of 2*m by n

uint8_t *tilted_block_bitor(uint8_t *x, int mx, int nx, 
		int msub, int nsub, double tiltangle) {
  static std::vector<uint8_t> block;

  int my = 1+(mx-1)/msub;
  int ny = 1+(nx-1)/nsub;
  block.resize(2*my*ny);
  int i_offset = mx/2;
  double increment = tan(tiltangle);

  for (int iy = 0; iy < 2*my*ny; iy++) {
    block[iy] = 0;
  }
  for (int jx = 0; jx < nx; jx++) {
    int jy = jx/nsub;
    int shift = (int) (increment * jx + 0.5);
    for (int ix = 0-i_offset; ix < mx+i_offset; ix++) {
      int ix_shifted = ix + shift;
      if ((ix_shifted>=0) && (ix_shifted<mx)){
        int iy = (ix+i_offset)/msub;
        block[iy+jy*(my*2)] |= *x++;
      }
    }
  }

  return &block[0];
}
