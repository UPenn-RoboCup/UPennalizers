/**
* @file Representations/MotionControl/MotionSelection.h
* This file declares a class that represents the motions actually selected based on the constraints given.
* @author <A href="mailto:Thomas.Roefer@dfki.de">Thomas Röfer</A>
*/

#pragma once

#include "MotionRequest.h"

/**
* @class MotionSelection
* A class that represents the motions actually selected based on the constraints given.
*/
class MotionSelection : public Streamable
{
private:
  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM(targetMotion, MotionRequest);
    STREAM(specialActionMode);
    STREAM(ratios);
    STREAM(specialActionRequest);
    STREAM(walkRequest);
    STREAM(bikeRequest);
    STREAM_REGISTER_FINISH();
  }

public:
  ENUM(ActivationMode,
    deactive,
    active,
    first
  );

  MotionRequest::Motion targetMotion; /**< The motion that is the destination of the current interpolation. */
  ActivationMode specialActionMode; /**< Whether and how the special action module is active. */
  float ratios[MotionRequest::numOfMotions]; /**< The current ratio of each motion in the final joint request. */
  SpecialActionRequest specialActionRequest; /**< The special action request, if it is an active motion. */
  WalkRequest walkRequest; /**< The walk request, if it is an active motion. */
  BikeRequest bikeRequest; /**< The bike request, if it is an active motion. */

  /**
  * Default constructor.
  */
  MotionSelection();
};
