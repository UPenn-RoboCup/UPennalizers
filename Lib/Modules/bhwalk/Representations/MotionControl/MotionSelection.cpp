/**
* @file Representations/MotionControl/MotionSelection.cpp
* This file implements a class that represents the motions actually selected based on the constraints given.
* @author <A href="mailto:Thomas.Roefer@dfki.de">Thomas R�fer</A>
*/

#include <cstring>

#include "MotionSelection.h"

MotionSelection::MotionSelection() : targetMotion(MotionRequest::stand), specialActionMode(deactive)
{
  memset(ratios, 0, sizeof(ratios));
  ratios[MotionRequest::stand] = 1;
}
