#include <vector>
#include <stdint.h>

#include "color_count.h"

int *color_count(uint8_t *x, int n) {
  static std::vector<int> count(nColor);

  for (int i = 0; i < nColor; i++) {
    count[i] = 0;
  }

  for (int i = 0; i < n; i++) {
    int label = x[i];
    count[label]++;
  }

  return &count[0];
}

int *color_count_obs(uint8_t *x, int n) {
  static std::vector<int> count(nColor);

  for (int i = 0; i < nColor; i++) {
    count[i] = 0;
  }

  for (int i = 0; i < n; i++) {
    int label = x[i];
    count[label]++;
  }

  return &count[0];
}
