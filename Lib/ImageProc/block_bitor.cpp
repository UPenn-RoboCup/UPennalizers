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
