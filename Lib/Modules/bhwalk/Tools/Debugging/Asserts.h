/**
 * @file Asserts.h
 * @author <a href="mailto:afabisch@tzi.de">Alexander Fabisch</a>
 * Some more complex assertions based on the ASSERT macro.
 */

#pragma once

#include "Platform/BHAssert.h"
#include <cmath>

#define ASSERT_EQUALS_DELTA(actual, expected, delta) \
  ASSERT(fabs((actual) - (expected)) <= (delta));

#define ASSERT_WITHIN(n, begin, end) \
  ASSERT((n) >= begin); ASSERT((n) <= end);

#define ASSERT_INDEX_WITHIN(i, begin, end) \
  ASSERT((i) >= begin); ASSERT((i) < end);

#define ASSERT_COORDINATES_WITHIN_IMAGE(x, y, cameraInfo) \
  ASSERT_INDEX_WITHIN(x, 0, (cameraInfo).resolutionWidth); \
  ASSERT_INDEX_WITHIN(y, 0, (cameraInfo).resolutionHeight);

#define ASSERT_POINT_WITHIN_IMAGE(p, cameraInfo) \
  ASSERT_COORDINATES_WITHIN_IMAGE((p).x, (p).y, cameraInfo)
