/**
* @file Modules/MotionControl/MotionSelector.h
* This file declares a module that is responsible for controlling the motion.
* @author <A href="mailto:Thomas.Roefer@dfki.de">Thomas R�fer</A>
* @author <A href="mailto:allli@tzi.de">Alexander H�rtl</A>
*/

#pragma once

//#include "Tools/Module/Module.h"
#include "Representations/Configuration/DamageConfiguration.h"
#include "Representations/Infrastructure/FrameInfo.h"
#include "Representations/MotionControl/SpecialActionsOutput.h"
#include "Representations/MotionControl/WalkingEngineOutput.h"
#include "Representations/MotionControl/WalkingEngineStandOutput.h"
//#include "Representations/MotionControl/BikeEngineOutput.h"
#include "Representations/MotionControl/MotionRequest.h"
#include "Representations/MotionControl/MotionSelection.h"
#include "Representations/Sensing/GroundContactState.h"

//MODULE(MotionSelector)
//  USES(SpecialActionsOutput)
//  USES(WalkingEngineOutput)
//  USES(WalkingEngineStandOutput)
//  USES(BikeEngineOutput)
//  REQUIRES(FrameInfo)
//  REQUIRES(MotionRequest)
//  REQUIRES(GroundContactState)
//  REQUIRES(DamageConfiguration)
//  PROVIDES_WITH_MODIFY(MotionSelection)
//END_MODULE

class MotionSelector //: public MotionSelectorBase
{
private:
//  PROCESS_WIDE_STORAGE_STATIC(MotionSelector) theInstance; /**< The only instance of this module. */

  bool forceStand;
  MotionRequest::Motion lastMotion;
  MotionRequest::Motion prevMotion;
  unsigned lastExecution;
  SpecialActionRequest::SpecialActionID lastActiveSpecialAction;

public:
  void update(MotionSelection& motionSelection,
            const MotionRequest& theMotionRequest,
            const WalkingEngineOutput& theWalkingEngineOutput,
            const GroundContactState& theGroundContactState,
            const DamageConfiguration& theDamageConfiguration,
            const FrameInfo& theFrameInfo);
  /**
  * Can be used to overwrite all other motion requests with a stand request.
  * Must be called again in every frame a stand is desired.
  */
  static void stand();
  /**
  * Default constructor.
  */
  MotionSelector() : lastMotion(MotionRequest::specialAction), prevMotion(MotionRequest::specialAction),
    lastActiveSpecialAction(SpecialActionRequest::playDead)
  {
//    theInstance = this;
  }
};
