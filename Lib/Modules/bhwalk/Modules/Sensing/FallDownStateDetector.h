/**
* @file FallDownStateDetector.h
*
* This file declares a module that provides information about the current state of the robot's body.
*
* @author <a href="mailto:maring@informatik.uni-bremen.de">Martin Ring</a>
*/

#pragma once

#include "Representations/Infrastructure/SensorData.h"
#include "Representations/Infrastructure/FrameInfo.h"
#include "Representations/MotionControl/MotionInfo.h"
#include "Representations/Modeling/FallDownState.h"
#include "Representations/Sensing/InertiaSensorData.h"
//#include "Tools/Module/Module.h"
#include "Tools/RingBufferWithSum.h"


//MODULE(FallDownStateDetector)
//  REQUIRES(FilteredSensorData)
//  REQUIRES(InertiaSensorData)
//  USES(MotionInfo)
//  REQUIRES(FrameInfo)
//  PROVIDES_WITH_MODIFY_AND_DRAW(FallDownState)
//END_MODULE


/**
* @class FallDownStateDetector
*
* A module for computing the current body state from sensor data
*/
class FallDownStateDetector //: public FallDownStateDetectorBase
{
private:
  /**
   * @class Parameters
   * The parameters for FallDownStateDetector
   */
  class Parameters : public Streamable
  {
  private:
    void serialize(In* in, Out* out)
    {
      STREAM_REGISTER_BEGIN();
      STREAM(staggeringAngleX);
      STREAM(staggeringAngleY);
      STREAM(fallDownAngleX);
      STREAM(fallDownAngleY);
      STREAM(fallTime);
      STREAM(onGroundAngle);
      STREAM_REGISTER_FINISH();
    }

  public:
    int   fallTime; /**< The time (in ms) to remain in state 'falling' after a detected fall */
    float staggeringAngleX, /**< The threshold angle which is used to detect the robot is staggering to the back or front*/
          staggeringAngleY, /**< The threshold angle which is used to detect the robot is staggering sidewards*/
          fallDownAngleY, /**< The threshold angle which is used to detect a fall to the back or front*/
          fallDownAngleX, /**< The threshold angle which is used to detect a sidewards fall */
          onGroundAngle; /**< The threshold angle which is used to detect the robot lying on the ground */
  };

  Parameters parameters; /**< The parameters of this module. */
  public:
  /** Executes this module
  * @param fallDownState The data structure that is filled by this module
  */
  void update(FallDownState& fallDownState,
          const FilteredSensorData& theFilteredSensorData,
          const FrameInfo& theFrameInfo,
          const InertiaSensorData& theInertiaSensorData);

  bool isGettingUp();
  bool isFalling(const FilteredSensorData& theFilteredSensorData);
  bool isStaggering(const FilteredSensorData& theFilteredSensorData);
//  bool isCalibrated();
//  bool impact(FallDownState& fallDownState);
  bool specialSpecialAction();
  bool isUprightOrStaggering(FallDownState& fallDownState);
  FallDownState::Direction directionOf(float angleX, float angleY);
  FallDownState::Sidestate sidewardsOf(FallDownState::Direction dir);

  unsigned int lastFallDetected;

  ENUM(KeeperJumped,
    None,
    KeeperJumpedLeft,
    KeeperJumpedRight
  );
  KeeperJumped keeperJumped; /**< Whether the keeper has recently executed a jump motion that has to be integrated in odometry offset. */

  /** Indices for buffers of sensor data */
  ENUM(BufferEntry, accX, accY, accZ);

  /** Buffers for averaging sensor data */
  RingBufferWithSum<float, 15> buffers[numOfBufferEntrys];

public:
  /**
  * Default constructor.
  */
  FallDownStateDetector();
};
