/**
* @file GroundContactDetector.cpp
*
* Implementation of module GroundContactDetector.
*
* @author <a href="mailto:fynn@informatik.uni-bremen.de">Fynn Feldpausch</a>
*/

#include "GroundContactDetector.h"
//#include "Tools/Debugging/DebugDrawings.h"
#include "Tools/Streams/InStreams.h"
//#include "Tools/Settings.h"
//#include "Platform/SoundPlayer.h"
#include <algorithm>
#include <iostream>

//MAKE_MODULE(GroundContactDetector, Sensing)

GroundContactDetector::GroundContactDetector() :
  contact(true), lastContact(true), contactStartTime(0), noContactStartTime(0)
{
    this->init();
}

void GroundContactDetector::init()
{
  InConfigMap stream("/usr/local/share/bhwalk/config/groundContact.cfg");
  if(stream.exists())
    stream >> p;
  else
  {
      std::cout << "Could not find groundContact.cfg!" << std::endl;
  }
}

struct GroundContactDetector::ContactState GroundContactDetector::checkFsr(bool left,
                                                                           const SensorData& theSensorData)
{
  ContactState state;
  float fsrValues[4] =
  {
    left ? theSensorData.data[SensorData::fsrLFL] : theSensorData.data[SensorData::fsrRFL],
    left ? theSensorData.data[SensorData::fsrLFR] : theSensorData.data[SensorData::fsrRFR],
    left ? theSensorData.data[SensorData::fsrLBL] : theSensorData.data[SensorData::fsrRBL],
    left ? theSensorData.data[SensorData::fsrLBR] : theSensorData.data[SensorData::fsrRBR]
  };

  int fsrs = 0;
  float fsrSum = 0.0f;
  for(int i = 0; i < 4; ++i)
  {
    if(fsrValues[i] < p.fsrLimit)
    {
      fsrSum += fsrValues[i];
      fsrs++;
    }
  }

  if(fsrs == 0)
  {
    state.contact = true;
    state.confidence = 0.25f;
    return state;
  }

  if(fsrSum == 0)
  {
    state.contact = false;
    state.confidence = 1.f;
    return state;
  }
  state.contact = fsrSum > p.fsrThreshold;

  float fsrMean = fsrSum / (float)fsrs;
  float fsrMSE = 0.f;
  for(int i = 0; i < 4; ++i)
  {
    if(fsrValues[i] < p.fsrLimit)
      fsrMSE += (fsrValues[i] - fsrMean) * (fsrValues[i] - fsrMean);
  }

  // conforms: 1 * (mean - sum)^2 + (fsrs - 1) * mean^2
  float fsrMaxMSE = (float)fsrs* fsrMean* fsrMean - 2 * fsrMean* fsrSum + fsrSum* fsrSum;

  // contact: confidence = deviation from fsrMean
  // no contact: confidence = deviation from zero
  state.confidence = state.contact ? 1 - fsrMSE / fsrMaxMSE : 1 - fsrSum / p.fsrThreshold;
  // temporary hack
  state.confidence = state.contact ? p.fsrThreshold / fsrSum : 1 - fsrSum / p.fsrThreshold;
  return state;
}

struct GroundContactDetector::ContactState GroundContactDetector::checkLoad(const SensorData& theSensorData)
{
  ContactState state;

  float loadSum = theSensorData.currents[JointData::LHipPitch];
  loadSum += theSensorData.currents[JointData::LKneePitch];
  loadSum += theSensorData.currents[JointData::LAnklePitch];
  loadSum += theSensorData.currents[JointData::RHipPitch];
  loadSum += theSensorData.currents[JointData::RKneePitch];
  loadSum += theSensorData.currents[JointData::RAnklePitch];
  loadSum += theSensorData.currents[JointData::LHipRoll];
  loadSum += theSensorData.currents[JointData::LHipYawPitch];
  loadSum += theSensorData.currents[JointData::LAnkleRoll];
  loadSum += theSensorData.currents[JointData::RHipRoll];
  loadSum += theSensorData.currents[JointData::RHipYawPitch];
  loadSum += theSensorData.currents[JointData::RAnkleRoll];
  // PLOT("module:GroundContactDetector:contactLoadSum", loadSum);

  state.contact = loadSum > p.loadThreshold;
  //max angleY: pi_4 (45�)
  state.confidence = 1 - std::min((float)fabs(theSensorData.data[SensorData::angleY]), pi_4) / pi_4;
  return state;
}

void GroundContactDetector::update(GroundContactState& groundContactState,
                                   const SensorData& theSensorData,
                                   const FrameInfo& theFrameInfo,
                                   const MotionRequest& theMotionRequest,
                                   const MotionInfo& theMotionInfo)
{
//  MODIFY("module:GroundContactDetector:parameters", p);
//  PLOT("module:GroundContactDetector:groundContact", groundContactState.contact ? 0.75 : 0.25);
//  PLOT("module:GroundContactDetector:groundContactSafe", groundContactState.contactSafe ? 0.75 : 0.25);
//  PLOT("module:GroundContactDetector:noGroundContactSafe", groundContactState.noContactSafe ? 0.75 : 0.25);

  if(p.forceContact)
  {
    groundContactState.contact = true;
    groundContactState.contactSafe = true;
    groundContactState.noContactSafe = false;
    return;
  }

  // states
  ContactState stateFsrLeft = checkFsr(true, theSensorData);
  ContactState stateFsrRight = checkFsr(false, theSensorData);
  ContactState stateLoad = checkLoad(theSensorData);
  // contact plots
//  PLOT("module:GroundContactDetector:contactLoad", stateLoad.contact ? 0.75 : 0.25);
//  PLOT("module:GroundContactDetector:contactFsrLeft", stateFsrLeft.contact ? 0.75 : 0.25);
//  PLOT("module:GroundContactDetector:contactFsrRight", stateFsrRight.contact ? 0.75 : 0.25);
  // confidence plots
//  PLOT("module:GroundContactDetector:confidenceLoad", stateLoad.confidence);
//  PLOT("module:GroundContactDetector:confidenceFsrLeft", stateFsrLeft.confidence);
//  PLOT("module:GroundContactDetector:confidenceFsrRight", stateFsrRight.confidence);

  float confidenceContact = 0.f;
  float confidenceNoContact = 0.f;
  if(stateFsrLeft.contact) confidenceContact += stateFsrLeft.confidence;
  else confidenceNoContact += stateFsrLeft.confidence;
  if(stateFsrRight.contact) confidenceContact += stateFsrRight.confidence;
  else confidenceNoContact += stateFsrRight.confidence;
  if(stateLoad.contact) confidenceContact += stateLoad.confidence;
  else confidenceNoContact += stateLoad.confidence;

  confidenceContactBuffer.add(confidenceContact);
  confidenceNoContactBuffer.add(confidenceNoContact);
  if(confidenceContactBuffer.getSum() >= BUFFER_SIZE * p.contactThreshold)
    contact = true;
  else if(confidenceNoContactBuffer.getSum() >= BUFFER_SIZE * p.noContactThreshold)
    contact = false;

  groundContactState.contact = contact || theMotionRequest.motion == MotionRequest::specialAction || theMotionInfo.motion == MotionRequest::specialAction;
//  PLOT("module:GroundContactDetector:contactThreshold", BUFFER_SIZE * p.contactThreshold);
//  PLOT("module:GroundContactDetector:noContactThreshold", BUFFER_SIZE * p.noContactThreshold);
//  PLOT("module:GroundContactDetector:confidenceContact", confidenceContactBuffer.getSum());
//  PLOT("module:GroundContactDetector:confidenceNoContact", confidenceNoContactBuffer.getSum());

  if((contact && !lastContact) || (contact && contactStartTime == 0))
    contactStartTime = theFrameInfo.time;
  groundContactState.contactSafe = contact && theFrameInfo.getTimeSince(contactStartTime) >= p.safeContactTime;
  if((!contact && lastContact) || (contact && noContactStartTime == 0))
  {
    noContactStartTime = theFrameInfo.time;
#ifndef TARGET_SIM
    // if(contactStartTime != 0 && theMotionInfo.motion == MotionRequest::walk)
    //   SoundPlayer::play("high.wav");
#endif
  }
  groundContactState.noContactSafe = !contact && theFrameInfo.getTimeSince(noContactStartTime) >= p.safeNoContactTime;

  lastContact = contact;
}
