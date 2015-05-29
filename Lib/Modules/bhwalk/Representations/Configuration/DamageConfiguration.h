/**
 * @file DamageConfiguration.h
 * Provides data about disabling some functions because of hardware failures.
 *
 * @author Benjamin Markowsky
 */

#pragma once

#include <string>
#include "Tools/Streams/Streamable.h"

class DamageConfiguration : public Streamable
{
public:
  DamageConfiguration() :
    useGroundContactDetection(true),
    useGroundContactDetectionForLEDs(true),
    useGroundContactDetectionForSafeStates(true),
    useGroundContactDetectionForSensorCalibration(true) {}

  bool useGroundContactDetection;
  bool useGroundContactDetectionForLEDs;
  bool useGroundContactDetectionForSafeStates;
  bool useGroundContactDetectionForSensorCalibration;

  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM(useGroundContactDetection);
    STREAM(useGroundContactDetectionForLEDs);
    STREAM(useGroundContactDetectionForSafeStates);
    STREAM(useGroundContactDetectionForSensorCalibration);
    STREAM_REGISTER_FINISH();
  }
};
