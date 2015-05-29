/**
* @file Representations/MotionControl/WalkingEngineOutput.h
* This file declares a class that represents the output of modules generating motion.
* @author <A href="mailto:Thomas.Roefer@dfki.de">Thomas Röfer</A>
*/

#pragma once

#include "Representations/Infrastructure/JointData.h"
#include "Representations/MotionControl/WalkRequest.h"

/**
* @class WalkingEnigeOutput
* A class that represents the output of the walking engine.
*/
class WalkingEngineOutput : public JointRequest
{
public:
  Pose2D speed; /**< The current walking speed in mm/s and rad/s. */
  Pose2D odometryOffset; /**< The body motion performed in this step. */
  Pose2D upcomingOdometryOffset; /**< The remaining odometry offset for the currently executed step. */
  bool upcomingOdometryOffsetValid; /**< Whether the \c upcomingOdometryOffset is precise enough to be used */
  bool isLeavingPossible; /**< Is leaving the motion module possible now? */
  float positionInWalkCycle; /**< The current position in the walk cycle in the range [0..1[. */
  bool enforceStand; /**< This allows the walking engine to enforce a stand motion selection. (good for exception handling) */
  float instability; /**< An evaluation of the current walk stability. */
  WalkRequest executedWalk; /**< The walk currently executed. */

  /**
  * Default constructor.
  */
  WalkingEngineOutput() : isLeavingPossible(true), positionInWalkCycle(0), enforceStand(false), instability(0.) {}

private:
  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM_BASE(JointRequest);
    STREAM(speed);
    STREAM(odometryOffset);
    STREAM(upcomingOdometryOffset);
    STREAM(upcomingOdometryOffsetValid);
    STREAM(isLeavingPossible);
    STREAM(positionInWalkCycle);
    STREAM(enforceStand);
    STREAM(instability);
    STREAM(executedWalk);
    STREAM_REGISTER_FINISH();
  }
};
