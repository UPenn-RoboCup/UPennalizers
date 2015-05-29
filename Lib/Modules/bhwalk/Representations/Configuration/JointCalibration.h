/**
* @file JointCalibration.h
* Declaration of a class for representing the calibration values of joints.
* @author <a href="mailto:Thomas.Roefer@dfki.de">Thomas Röfer</a>
*/

#pragma once

#include "Representations/Infrastructure/JointData.h"

class JointCalibration : public Streamable
{
private:
  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM(joints);
    STREAM_REGISTER_FINISH()
  }

public:
  class JointInfo : public Streamable
  {
  private:
    virtual void serialize(In* in, Out* out)
    {
      STREAM_REGISTER_BEGIN();
      float offset = toDegrees(this->offset);
      STREAM(offset);
      STREAM(sign);
      float maxAngle = toDegrees(this->maxAngle),
            minAngle = toDegrees(this->minAngle);
      STREAM(minAngle);
      STREAM(maxAngle);
      if(in)
      {
        this->offset = fromDegrees(offset);
        this->minAngle = fromDegrees(minAngle);
        this->maxAngle = fromDegrees(maxAngle);
      }
      STREAM_REGISTER_FINISH()
    }

  public:
    float offset; /**< An offset added to the angle. */
    short sign; /**< A multiplier for the angle (1 or -1). */
    float maxAngle; /** the maximal angle in radians */
    float minAngle;  /** the minmal angle in radians */

    /**
    * Default constructor.
    */
    JointInfo() : offset(0), sign(1), maxAngle(2.618f), minAngle(-2.618f) {}
  };

  JointInfo joints[JointData::numOfJoints]; /**< Information on the calibration of all joints. */
};
