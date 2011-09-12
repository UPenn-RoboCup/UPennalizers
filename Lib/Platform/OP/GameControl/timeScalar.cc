#include "timeScalar.h"
#include <sys/time.h>
#include <stdlib.h>

double time_scalar() {
  static struct timeval t;
  gettimeofday(&t, NULL);
  return t.tv_sec + 1E-6*t.tv_usec;
}
