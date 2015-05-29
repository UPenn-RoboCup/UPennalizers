/**
* @file RobotModelProvider.h
*
* This file declares a module that provides information about the current state of the robot's limbs.
*
* @author <a href="mailto:allli@informatik.uni-bremen.de">Alexander H�rtl</a>
*/

#pragma once

//#include "Tools/Module/Module.h"
#include "Representations/Sensing/RobotModel.h"
#include "Representations/Configuration/RobotDimensions.h"
#include "Representations/Configuration/MassCalibration.h"
#include "Representations/Infrastructure/JointData.h"


//MODULE(RobotModelProvider)
//  REQUIRES(RobotDimensions)
//  REQUIRES(FilteredJointData)
//  REQUIRES(MassCalibration)
//  PROVIDES_WITH_MODIFY_AND_DRAW(RobotModel)
//END_MODULE


/**
* @class RobotModelProvider
*
* A module for computing the current state of the robot's limbs
*/
class RobotModelProvider //: public RobotModelProviderBase
{
public:

  /** Executes this module
  * @param robotModel The data structure that is filled by this module
  */
    void update(RobotModel& robotModel,
            const FilteredJointData& theFilteredJointData,
            const RobotDimensions& theRobotDimensions,
            const MassCalibration& theMassCalibration);


};
