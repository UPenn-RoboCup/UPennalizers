/**
* @file TorsoMatrix.h
* Declaration of class TorsoMatrix.
* @author Colin Graf
*/

#pragma once

#include "Tools/Math/Pose3D.h"

/**
* @class TorsoMatrix
* Matrix describing the transformation from ground to the robot torso.
*/
class TorsoMatrix : public Pose3D
{
public:
  Pose3D offset; /**< The estimated offset (including odometry) from last torso matrix to this one. (relative to the torso) */
  bool isValid; /**< Matrix is only valid if robot is on ground. */

  /** Default constructor. */
  TorsoMatrix() : isValid(false) {}

private:
  /**
  * The method makes the object streamable.
  * @param in The stream from which the object is read
  * @param out The stream to which the object is written
  */
  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM_BASE(Pose3D);
    STREAM(offset);
    STREAM(isValid);
    STREAM_REGISTER_FINISH();
  }
};
