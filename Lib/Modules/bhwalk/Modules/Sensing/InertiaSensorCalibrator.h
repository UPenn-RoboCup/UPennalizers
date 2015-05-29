/**
* @file InertiaSensorCalibrator.h
* Declaration of module InertiaSensorCalibrator.
* @author Colin Graf
*/

#pragma once

//#include "Tools/Module/Module.h"
#include "Tools/RingBuffer.h"
#include "Tools/RingBufferWithSum.h"
#include "Tools/Math/Kalman.h"
#include "Representations/Infrastructure/FrameInfo.h"
//#include "Representations/Infrastructure/RobotInfo.h"
#include "Representations/Sensing/InertiaSensorData.h"
#include "Representations/Sensing/RobotModel.h"
#include "Representations/Sensing/GroundContactState.h"
#include "Representations/MotionControl/MotionSelection.h"
#include "Representations/MotionControl/MotionInfo.h"
#include "Representations/MotionControl/WalkingEngineOutput.h"
#include "Representations/Configuration/JointCalibration.h"
#include "Representations/Configuration/DamageConfiguration.h"

//MODULE(InertiaSensorCalibrator)
//  REQUIRES(InspectedInertiaSensorData)
//  REQUIRES(RobotModel)
//  REQUIRES(FrameInfo)
//  REQUIRES(RobotInfo)
//  REQUIRES(GroundContactState)
//  REQUIRES(JointCalibration)
//  REQUIRES(DamageConfiguration)
//  USES(MotionSelection)
//  USES(MotionInfo)
//  USES(WalkingEngineOutput)
//  PROVIDES_WITH_MODIFY(InertiaSensorData)
//END_MODULE

/**
* @class InertiaSensorCalibrator
* A module for determining the bias of the inertia sensor readings.
*/
class InertiaSensorCalibrator //: public InertiaSensorCalibratorBase
{
public:
  /** Default constructor. */
  InertiaSensorCalibrator();

private:
  /**
  * Parameters for this module.
  */
  class Parameters : public Streamable
  {
  public:
    unsigned int timeFrame; /**< The time frame within unstable situations lead to dropping averaged gyro and acceleration measurements. (in ms) */
    Vector2<> gyroBiasProcessNoise; /**< The process noise of the gyro offset estimator. */
    Vector2<> gyroBiasStandMeasurementNoise; /**< The noise of gyro measurements and the gyro offset while standing. */
    Vector2<> gyroBiasWalkMeasurementNoise; /**< The noise of gyro measurements and the gyro offset while walking. */
    Vector3<> accBiasProcessNoise; /**< The process noise of the acceleration sensor offset estimator. */
    Vector3<> accBiasStandMeasurementNoise; /**< The noise of acceleration sensor measurements and the acceleration sensor offset while standing. */
    Vector3<> accBiasWalkMeasurementNoise; /**< The noise of acceleration sensor measurements and the acceleration sensor offset while walking. */

  private:
    /**
    * The method makes the object streamable.
    * @param in The stream from which the object is read.
    * @param out The stream to which the object is written.
    */
    virtual void serialize(In* in, Out* out)
    {
      STREAM_REGISTER_BEGIN();
      STREAM(timeFrame);
      STREAM(gyroBiasProcessNoise);
      STREAM(gyroBiasStandMeasurementNoise);
      STREAM(gyroBiasWalkMeasurementNoise);
      STREAM(accBiasProcessNoise);
      STREAM(accBiasStandMeasurementNoise);
      STREAM(accBiasWalkMeasurementNoise);
      STREAM_REGISTER_FINISH();
    }
  };

  /**
  * Class for buffering averaged gyro and acceleration sensor readings.
  */
  class Collection
  {
  public:
    Vector3<> accAvg; /**< The average of acceleration sensor readings of one walking phase or 1 sec. */
    Vector2<> gyroAvg; /**< The average of gyro sensor eadings of one walking phase or 1 sec. */
    unsigned int timeStamp; /**< When this collection was created. */
    MotionRequest::Motion motion; /**< The motion that was active while collecting sensor readings. */

    /**
    * Constructs a collection.
    */
    Collection(const Vector3<>& accAvg, const Vector2<>& gyroAvg, unsigned int timeStamp, MotionRequest::Motion motion) :
      accAvg(accAvg), gyroAvg(gyroAvg), timeStamp(timeStamp), motion(motion) {}

    /**
    * Default constructor.
    */
    Collection() {};
  };

  Parameters p; /**< The parameters of the module. */

  Vector2<> safeGyro; /**< The last valid gyro readings. */
  Vector3<> safeAcc; /**< The last valid acceleration sensor readings. */
  int inertiaSensorDrops; /**< The count of continuously dropped sensor readings. */

  bool calibrated; /**< Whether the filters are initialized. */
  Kalman<float> accXBias; /**< The calibration bias of accX. */
  Kalman<float> accYBias; /**< The calibration bias of accY. */
  Kalman<float> accZBias; /**< The calibration bias of accZ. */
  Kalman<float> gyroXBias; /**< The calibration bias of gyroX. */
  Kalman<float> gyroYBias; /**< The calibration bias of gyroY. */

  unsigned int collectionStartTime; /**< When the current collection was started. */
  unsigned int cleanCollectionStartTime; /**< When the last unstable situation was over. */

  RingBufferWithSum<Vector3<>, 300> accValues; /**< Ringbuffer for collecting the acceleration sensor values of one walking phase or 1 sec. */
  RingBufferWithSum<Vector2<>, 300> gyroValues; /**< Ringbuffer for collecting the gyro sensor values of one walking phase or 1 sec. */

  RingBuffer<Collection, 50> collections; /**< Buffered averaged gyro and accleration sensor readings. */

  unsigned int lastTime; /**< The time of the previous iteration. */
  MotionRequest::Motion lastMotion; /**< The executed motion of the previous iteration. */
  double lastPositionInWalkCycle; /**< The walk cycle position of the previous iteration. */

  RotationMatrix calculatedRotation; /**< Body rotation, which was calculated using kinematics. */

#ifndef RELEASE
  JointCalibration lastJointCalibration; /**< Some parts of the joint calibration of the previous iteration. */
#endif

  public:
  /**
  * Resets all internal values (including determined calibration) of this module.
  */
  void reset();


  /**
  * Updates the InertiaSensorData representation.
  * @param inertiaSensorData The inertia sensor data representation which is updated by this module.
  */
  void update(InertiaSensorData& inertiaSensorData,
          const InspectedInertiaSensorData& theInspectedInertiaSensorData,
          const FrameInfo& theFrameInfo,
          const RobotModel& theRobotModel,
          const GroundContactState& theGroundContactState,
          const MotionSelection& theMotionSelection,
          const MotionInfo& theMotionInfo,
          const WalkingEngineOutput& theWalkingEngineOutput,
          const DamageConfiguration& theDamageConfiguration);
};
