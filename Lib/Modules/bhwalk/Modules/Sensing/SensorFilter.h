/**
* @file SensorFilter.h
* Declaration of module SensorFilter.
* @author Colin Graf
*/

#pragma once

//#include "Tools/Module/Module.h"
#include "Representations/Infrastructure/SensorData.h"
#include "Representations/Sensing/InertiaSensorData.h"
#include "Representations/Sensing/OrientationData.h"

//MODULE(SensorFilter)
//  REQUIRES(SensorData)
//  REQUIRES(InertiaSensorData)
//  REQUIRES(OrientationData)
//  PROVIDES_WITH_MODIFY_AND_OUTPUT(FilteredSensorData)
//END_MODULE

/**
* A module for sensor data filtering.
*/
class SensorFilter //: public SensorFilterBase
{
public:
  /**
  * Updates the FilteredSensorData representation.
  * @param filteredSensorData The sensor data representation which is updated by this module.
  */
  void update(FilteredSensorData& filteredSensorData,
          const InertiaSensorData& theInertiaSensorData,
          const SensorData& theSensorData,
          const OrientationData& theOrientationData);

#ifndef RELEASE
  float gyroAngleXSum;
  unsigned int lastIteration;
#endif
};
