/**
 * @file FallDownStateDetector.cpp
 *
 * This file implements a module that provides information about the current state of the robot's body.
 *
 * @author <a href="mailto:maring@informatik.uni-bremen.de">Martin Ring</a>
 */

#include "FallDownStateDetector.h"
#include "Representations/Infrastructure/JointData.h"
//#include "Platform/SoundPlayer.h"
#include "Tools/Streams/InStreams.h"
//#include "Tools/Settings.h"
//#include "Tools/Debugging/DebugDrawings.h"

FallDownStateDetector::FallDownStateDetector()
{
  InConfigMap stream("/usr/local/share/bhwalk/config/fallDownStateDetector.cfg");
  if(stream.exists())
    stream >> parameters;
  else
  {
    InConfigMap stream("/usr/local/share/bhwalk/config/fallDownStateDetector.cfg");
    ASSERT(stream.exists());
    stream >> parameters;
  }
  parameters.fallDownAngleX *= pi_180;
  parameters.fallDownAngleY *= pi_180;
  parameters.onGroundAngle  *= pi_180;
  parameters.staggeringAngleX *= pi_180;
  parameters.staggeringAngleY *= pi_180;

  lastFallDetected = (unsigned int) - parameters.fallTime;
}

void FallDownStateDetector::update(FallDownState& fallDownState,
        const FilteredSensorData& theFilteredSensorData,
        const FrameInfo& theFrameInfo,
        const InertiaSensorData& theInertiaSensorData)
{
//  DECLARE_PLOT("module:FallDownStateDetector:accelerationAngleXZ");
//  DECLARE_PLOT("module:FallDownStateDetector:accelerationAngleYZ");

  // Buffer data:
  buffers[accX].add(theFilteredSensorData.data[SensorData::accX]);
  buffers[accY].add(theFilteredSensorData.data[SensorData::accY]);
  buffers[accZ].add(theFilteredSensorData.data[SensorData::accZ]);

  // Compute average acceleration values and angles:
  float accXaverage(buffers[accX].getAverage());
  float accYaverage(buffers[accY].getAverage());
  float accZaverage(buffers[accZ].getAverage());
  float accelerationAngleXZ(atan2f(accZaverage, accXaverage));
  float accelerationAngleYZ(atan2f(accZaverage, accYaverage));
//  MODIFY("module:FallDownStateDetector:accX",  accXaverage);
//  MODIFY("module:FallDownStateDetector:accY",  accYaverage);
//  MODIFY("module:FallDownStateDetector:accZ",  accZaverage);
//  MODIFY("module:FallDownStateDetector:accAngleXZ", accelerationAngleXZ);
//  MODIFY("module:FallDownStateDetector:accAngleYZ", accelerationAngleYZ);
//  PLOT("module:FallDownStateDetector:accelerationAngleXZ", accelerationAngleXZ);
//  PLOT("module:FallDownStateDetector:accelerationAngleYZ", accelerationAngleYZ);

  fallDownState.odometryRotationOffset = 0;

  if(theInertiaSensorData.calibrated && !specialSpecialAction())
  {
    if(theFrameInfo.getTimeSince(lastFallDetected) <= parameters.fallTime)// && !impact(fallDownState))
    {
      fallDownState.state = FallDownState::falling;
    }
    else if((fabs(theFilteredSensorData.data[SensorData::angleX]) <= parameters.staggeringAngleX - pi_180
             && fabs(theFilteredSensorData.data[SensorData::angleY]) <= parameters.staggeringAngleY - pi_180)
            || (fallDownState.state == FallDownState::upright && !isStaggering(theFilteredSensorData)))
    {
      fallDownState.state = FallDownState::upright;
      fallDownState.direction = FallDownState::none;
      fallDownState.sidewards = FallDownState::noot;
    }
    else if(fallDownState.state == FallDownState::staggering && isFalling(theFilteredSensorData))
    {
      //SoundPlayer::play("doh.wav");
      lastFallDetected = theFrameInfo.time;
      fallDownState.state = FallDownState::falling;
      fallDownState.direction = directionOf(theFilteredSensorData.data[SensorData::angleX], theFilteredSensorData.data[SensorData::angleY]);
      if(fallDownState.sidewards != FallDownState::fallen)
      {
        fallDownState.sidewards = sidewardsOf(fallDownState.direction);
      }
    }
    else if((isUprightOrStaggering(fallDownState)
             && isStaggering(theFilteredSensorData))
            || (fallDownState.state == FallDownState::staggering
                && fabs(theFilteredSensorData.data[SensorData::angleX]) <= parameters.staggeringAngleX - pi_180
                && fabs(theFilteredSensorData.data[SensorData::angleY]) <= parameters.staggeringAngleY - pi_180))
    {
      fallDownState.state = FallDownState::staggering;
      fallDownState.direction = directionOf(theFilteredSensorData.data[SensorData::angleX], theFilteredSensorData.data[SensorData::angleY]);
      if(fallDownState.sidewards != FallDownState::fallen)
      {
        fallDownState.sidewards = sidewardsOf(fallDownState.direction);
      }
    }
    else
    {
      fallDownState.state = FallDownState::undefined;

      if(!isGettingUp())
      {
        if(fabs(accelerationAngleXZ) < 0.5f)
        {
          fallDownState.state = FallDownState::onGround;
          fallDownState.direction = FallDownState::front;
          if(fallDownState.sidewards == FallDownState::leftwards)
          {
            fallDownState.odometryRotationOffset = -pi_2;
            fallDownState.sidewards = FallDownState::fallen;
          }
          else if(fallDownState.sidewards == FallDownState::rightwards)
          {
            fallDownState.odometryRotationOffset = pi_2;
            fallDownState.sidewards = FallDownState::fallen;
          }
        }
        else if(fabs(accelerationAngleXZ) > 2.5f)
        {
          fallDownState.state = FallDownState::onGround;
          fallDownState.direction = FallDownState::back;
          if(fallDownState.sidewards == FallDownState::leftwards)
          {
            fallDownState.odometryRotationOffset = pi_2;
            fallDownState.sidewards = FallDownState::fallen;
          }
          else if(fallDownState.sidewards == FallDownState::rightwards)
          {
            fallDownState.odometryRotationOffset = -pi_2;
            fallDownState.sidewards = FallDownState::fallen;
          }
        }
        else if(fabs(accelerationAngleYZ) < 0.5f)
        {
          fallDownState.state = FallDownState::onGround;
          fallDownState.direction = FallDownState::left;
          if(fallDownState.sidewards != FallDownState::fallen)
          {
            fallDownState.sidewards = FallDownState::leftwards;
          }
        }
        else if(fabs(accelerationAngleYZ) > 2.5f)
        {
          fallDownState.state = FallDownState::onGround;
          fallDownState.direction = FallDownState::right;
          if(fallDownState.sidewards != FallDownState::fallen)
          {
            fallDownState.sidewards = FallDownState::rightwards;
          }
        }
      }
    }
  }
  else
  {
    fallDownState.state = FallDownState::undefined;
  }
}

bool FallDownStateDetector::isUprightOrStaggering(FallDownState& fallDownState)
{
  return fallDownState.state == FallDownState::upright
         || fallDownState.state == FallDownState::staggering;
}

//TODO: I don't think these are important since the bhwalk engine shouldn't be concerned
//with the robot getting up or not
bool FallDownStateDetector::isGettingUp()
{
    return false;
//  return theMotionInfo.motion == MotionRequest::specialAction
//         && (theMotionInfo.specialActionRequest.specialAction == SpecialActionRequest::standUpFrontNao
//             || theMotionInfo.specialActionRequest.specialAction == SpecialActionRequest::standUpBackNao);
}

bool FallDownStateDetector::specialSpecialAction()
{
    return false;
//  return theMotionInfo.motion == MotionRequest::specialAction
//          && theMotionInfo.specialActionRequest.specialAction == SpecialActionRequest::playDead;
}

bool FallDownStateDetector::isStaggering(const FilteredSensorData& theFilteredSensorData)
{
  return fabs(theFilteredSensorData.data[SensorData::angleX]) >= parameters.staggeringAngleX + pi_180
         || fabs(theFilteredSensorData.data[SensorData::angleY]) >= parameters.staggeringAngleY + pi_180;
}

bool FallDownStateDetector::isFalling(const FilteredSensorData& theFilteredSensorData)
{
  return fabs(theFilteredSensorData.data[SensorData::angleX]) >= parameters.fallDownAngleX
         || fabs(theFilteredSensorData.data[SensorData::angleY]) >= parameters.fallDownAngleY;
}
//
//bool FallDownStateDetector::isCalibrated()
//{
////  return theInertiaSensorData.calibrated;
//}
//
//bool FallDownStateDetector::impact(FallDownState& fallDownState)
//{
////  switch(fallDownState.direction)
////  {
////  case FallDownState::back:
////    return theFilteredSensorData.accX < -1.15f;
////  case FallDownState::front:
////    return theFilteredSensorData.accX > 1.15f;
////  case FallDownState::left:
////    return theFilteredSensorData.accY < -1.15f;
////  case FallDownState::right:
////    return theFilteredSensorData.accY < -1.15f;
////  default:
////    return false;
////  }
//}

FallDownState::Direction FallDownStateDetector::directionOf(float angleX, float angleY)
{
  if(fabs(angleX) > fabs(angleY) + 0.2f)
  {
    if(angleX > 0.f) return FallDownState::left;
    else return FallDownState::right;
  }
  else
  {
    if(angleY > 0.f) return FallDownState::front;
    else return FallDownState::back;
  }
}

FallDownState::Sidestate FallDownStateDetector::sidewardsOf(FallDownState::Direction dir)
{
  switch(dir)
  {
  case FallDownState::left:
    return FallDownState::leftwards;
  case FallDownState::right:
    return FallDownState::rightwards;
  default:
    return FallDownState::noot;
  }
}

//MAKE_MODULE(FallDownStateDetector, Sensing)
