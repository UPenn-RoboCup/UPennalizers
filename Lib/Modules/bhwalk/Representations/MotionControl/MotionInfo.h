/**
* @file MotionInfo.h
* Definition of class MotionInfo.
* @author Martin Lötzsch
*/

#pragma once

#include "MotionRequest.h"

/**
* @class MotionInfo
* The executed motion request and additional information about the motions which are executed by the Motion process.
*/
class MotionInfo : public MotionRequest
{
public:
  bool isMotionStable; /**< If true, the motion is stable, leading to a valid torso / camera matrix. */
  Pose2D upcomingOdometryOffset; /**< The remaining odometry offset for the currently executed motion. */
  bool upcomingOdometryOffsetValid; /**< Whether the \c upcomingOdometryOffset is precise enough to be used */

  /** Default constructor. */
  MotionInfo() : isMotionStable(false) {}

private:
  /**
  * The method makes the object streamable.
  * @param in The stream from which the object is read
  * @param out The stream to which the object is written
  */
  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM_BASE(MotionRequest);
    STREAM(isMotionStable);
    STREAM(upcomingOdometryOffset);
    STREAM(upcomingOdometryOffsetValid);
    STREAM_REGISTER_FINISH();
  }
};
