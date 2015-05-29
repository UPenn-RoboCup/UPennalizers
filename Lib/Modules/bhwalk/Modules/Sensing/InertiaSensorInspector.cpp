/**
* @file InertiaSensorInspector.cpp
* Implementation of module InertiaSensorInspector.
* @author Colin Graf
*/

#include "InertiaSensorInspector.h"

//MAKE_MODULE(InertiaSensorInspector, Sensing)

InertiaSensorInspector::InertiaSensorInspector() : lastAcc(0.f, 0.f, -9.80665f), inertiaSensorDrops(1000)
{
  p.maxGyroOffset = Vector2<>(1.f, 1.f);
  p.maxAccOffset = Vector3<>(10.f, 10.f, 10.f);
}

void InertiaSensorInspector::update(InspectedInertiaSensorData& inertiaSensorData,
                                    const SensorData& theSensorData)
{
//  MODIFY("module:InertiaSensorInspector:parameters", p);

  // drop corrupted sensor readings
  Vector2<>& newGyro = inertiaSensorData.gyro;
  Vector3<>& newAcc = inertiaSensorData.acc;
  newGyro = Vector2<>(theSensorData.data[SensorData::gyroX], theSensorData.data[SensorData::gyroY]);
  newAcc = Vector3<>(theSensorData.data[SensorData::accX], theSensorData.data[SensorData::accY], theSensorData.data[SensorData::accZ]);
  newAcc *= 9.80665f; // strange unit => metric unit :)
  if(fabs(newGyro.x - lastGyro.x) > p.maxGyroOffset.x ||
     fabs(newGyro.y - lastGyro.y) > p.maxGyroOffset.y ||
     fabs(newAcc.x - lastAcc.x) > p.maxAccOffset.x ||
     fabs(newAcc.y - lastAcc.y) > p.maxAccOffset.y ||
     fabs(newAcc.z - lastAcc.z) > p.maxAccOffset.z)
  {
    if(++inertiaSensorDrops > 3)
    {
      lastGyro = newGyro;
      lastAcc = newAcc;
    }
    newGyro.x = newGyro.y = newAcc.x = newAcc.y = newAcc.z = InertiaSensorData::off;
  }
  else
  {
    inertiaSensorDrops = 0;
    lastGyro = newGyro;
    lastAcc = newAcc;
  }
}
