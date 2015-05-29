/**
* @file Representations/MotionControl/WalkingEngineStandOutput.h
* This file declares a class that represents the output of modules generating motion.
* @author <A href="mailto:Thomas.Roefer@dfki.de">Thomas Röfer</A>
*/

#pragma once

#include "Representations/Infrastructure/JointData.h"

/**
* @class WalkingEngineOutput
* A class that represents the output of the walking engine.
*/
class WalkingEngineStandOutput : public JointRequest
{
protected:
  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM_BASE(JointRequest);
    STREAM_REGISTER_FINISH();
  }

public:
  /**
  * Default constructor.
  */
  WalkingEngineStandOutput() {}
};
