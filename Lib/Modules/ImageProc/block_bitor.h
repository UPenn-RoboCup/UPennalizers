#ifndef block_bitor_h_DEFINED
#define block_bitor_h_DEFINED

#include <stdint.h>

uint8_t *block_bitor(uint8_t *x, int mx, int nx, int msub, int nsub);
uint8_t *block_bitor_obs(uint8_t *x, int mx, int nx, int msub, int nsub);
uint8_t *tilted_block_bitor(uint8_t *x, int mx, int nx, int msub, int nsub, double tiltangle);

#endif
