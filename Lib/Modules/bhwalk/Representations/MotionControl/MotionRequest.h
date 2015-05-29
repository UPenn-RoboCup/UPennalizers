/**
* @file Representations/MotionControl/MotionRequest.h
* This file declares a class that represents the motions that can be requested from the robot.
* @author <A href="mailto:Thomas.Roefer@dfki.de">Thomas Röfer</A>
*/

#pragma once

#include "SpecialActionRequest.h"
#include "WalkRequest.h"
#include "BikeRequest.h"

/**
* @class MotionRequest
* A class that represents the motions that can be requested from the robot.
*/
class MotionRequest : public Streamable
{
public:
  ENUM(Motion,
    walk,
    bike,
    specialAction,
    stand
  );

  Motion motion; /**< The selected motion. */
  SpecialActionRequest specialActionRequest; /**< The special action request, if it is the selected motion. */
  WalkRequest walkRequest; /**< The walk request, if it is the selected motion. */
  BikeRequest bikeRequest; /**< The kick request, if it is the selected motion. */

  /**
  * Default constructor.
  */
  MotionRequest() : motion(specialAction) {}

  /**
  * Prints the motion request to a readable string. (E.g. "walk: 100mm/s 0mm/s 0°/s")
  * @param destination The string to fill
  */
  void printOut(char* destination) const;

  /** Draws something*/
  void draw() const;

protected:
  /**
  * Makes the object streamable
  * @param in The stream from which the object is read
  * @param out The stream to which the object is written
  */
  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM(motion);
    STREAM(specialActionRequest);
    STREAM(walkRequest);
    STREAM(bikeRequest);
    STREAM_REGISTER_FINISH();
  }
};
