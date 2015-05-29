/**
* @file InertiaSensorData.h
* Declaration of class InertiaSensorData.
* @author Colin Graf
*/

#pragma once

#include "Tools/Math/Vector2.h"
#include "Tools/Math/Vector3.h"
#include "Representations/Infrastructure/SensorData.h"

/**
* @class InertiaSensorData
* Encapsulates inertia sensor data.
*/
class InertiaSensorData : public Streamable
{
public:
  enum
  {
    off = SensorData::off, /**< A special value to indicate that the sensor is missing. */
  };

  Vector2<float> gyro; /**< The change in orientation around the x- and y-axis. (in radian/s) */
  Vector3<float> acc; /**< The acceleration along the x-, y- and z-axis. (in m/s^2) */
  bool calibrated; /**< Whether the inertia sensors are calibrated or not */

  /** Default constructor. */
  InertiaSensorData() : calibrated(false) {}

private:
  /**
  * The method makes the object streamable.
  * @param in The stream from which the object is read
  * @param out The stream to which the object is written
  */
  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM(gyro);
    STREAM(acc);
    STREAM(calibrated);
    STREAM_REGISTER_FINISH();
  }
};

/**
* @class InspectedInertiaSensorData
* Encapsulates inspected inertia sensor data.
*/
class InspectedInertiaSensorData : public InertiaSensorData {};
