/**
* @file OrientationData.h
* Declaration of class OrientationData.
* @author Colin Graf
*/

#pragma once

#include "Tools/Math/Vector2.h"
#include "Tools/Math/Vector3.h"

/**
* @class OrientationData
* Encapsulates the orientation and velocity of the torso.
*/
class OrientationData : public Streamable
{
public:
  Vector2<float> orientation; /**< The rotation around the x- and y-axis relative to an orthognal position to the ground. (in radians) */
  Vector3<float> velocity; /**< The velocity along the x-, y- and z-axis relative to the toros. (in m/s) */

  /** Default constructor. */
  OrientationData() {}

private:
  /**
  * The method makes the object streamable.
  * @param in The stream from which the object is read
  * @param out The stream to which the object is written
  */
  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM(orientation);
    STREAM(velocity);
    STREAM_REGISTER_FINISH();
  }
};

class GroundTruthOrientationData  : public OrientationData {};
