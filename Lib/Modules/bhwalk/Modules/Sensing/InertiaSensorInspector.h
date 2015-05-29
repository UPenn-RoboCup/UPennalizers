/**
* @file InertiaSensorInspector.h
* Declaration of module InertiaSensorInspector.
* @author Colin Graf
*/

#pragma once

//#include "Tools/Module/Module.h"
#include "Representations/Infrastructure/SensorData.h"
#include "Representations/Sensing/InertiaSensorData.h"

//MODULE(InertiaSensorInspector)
//  REQUIRES(SensorData)
//  PROVIDES_WITH_MODIFY(InspectedInertiaSensorData)
//END_MODULE

/**
* @class InertiaSensorInspector
* A module for dropping invalid sensor readings from the imu.
*/
class InertiaSensorInspector //: public InertiaSensorInspectorBase
{
public:
  /** Default constructor. */
  InertiaSensorInspector();

private:
  /**
  * Parameters for this module.
  */
  class Parameters : public Streamable
  {
  public:
    Vector2<> maxGyroOffset; /**< Maximum allowed deviance of expected and measured gyro values, used for detecting corrupted readings. */
    Vector3<> maxAccOffset; /**< Maximum allowed deviance of expected and measured acc values, used for detecting corrupted readings. */

  private:
    /**
    * The method makes the object streamable.
    * @param in The stream from which the object is read.
    * @param out The stream to which the object is written.
    */
    virtual void serialize(In* in, Out* out)
    {
      STREAM_REGISTER_BEGIN();
      STREAM(maxGyroOffset);
      STREAM(maxAccOffset);
      STREAM_REGISTER_FINISH();
    }
  };


  Parameters p; /**< The parameters of the module. */

  Vector2<> lastGyro; /**< Some gyro readings that might be corruped, used for detecting corrupted readings. */
  Vector3<> lastAcc; /**< Some acceleration sensor readings that might be corruped, used for detecting corrupted readings. */
  int inertiaSensorDrops; /**< The count of continuously dropped sensor readings. */

  public:
  /**
  * Updates the InertiaSensorData representation.
  * @param inertiaSensorData The inertia sensor data representation which is updated by this module.
  */
  void update(InspectedInertiaSensorData& inertiaSensorData, const SensorData& theSensorData);
};
