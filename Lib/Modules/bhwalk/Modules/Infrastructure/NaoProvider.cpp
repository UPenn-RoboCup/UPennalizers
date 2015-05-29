/**
* @file Modules/Infrastructure/NaoProvider.cpp
* The file declares a module that provides information from the Nao via DCM.
* @author <a href="mailto:Thomas.Roefer@dfki.de">Thomas R�fer</a>
*/

//#define MEASURE_DELAY

#include <cstdio>

#include "NaoProvider.h"
//#include "Platform/SystemCall.h"

#ifdef MEASURE_DELAY
#include "Tools/Streams/InStreams.h"
#endif
//#include "Tools/Debugging/DebugDrawings.h"
//#include "Tools/Settings.h"

//#include "libbhuman/bhuman.h"

//PROCESS_WIDE_STORAGE(NaoProvider) NaoProvider::theInstance = 0;

NaoProvider::NaoProvider()// : lastUsSendTime(0), lastUsSwitchTime(0), lastUsReadTime(0), currentUsMode(0)
{
//  NaoProvider::theInstance = this;

//  OUTPUT(idText, text, "Hi, I am " << Global::getSettings().robot << ".");
//  OUTPUT(idRobotname, bin, Global::getSettings().robot);

#ifndef RELEASE
  for(int i = 0; i < JointData::numOfJoints; ++i)
    clippedLastFrame[i] = JointData::off;
#endif
//  for(int i = 0; i < BoardInfo::numOfBoards; ++i)
//  {
//    lastAck[i] = 0;
//    lastTimeWhenAck[i] = 0;
//  }
//
//  usSettings.sendInterval = 70;
//  usSettings.switchInterval = 250;
//  usSettings.ignoreAfterSwitchInterval = 150;
//  usSettings.modes.resize(4);
//  usSettings.modes[0] = 0.f;
//  usSettings.modes[1] = 2.f;
//  usSettings.modes[2] = 3.f;
//  usSettings.modes[3] = 1.f;
}

NaoProvider::~NaoProvider()
{
//  NaoProvider::theInstance = 0;
}

//bool NaoProvider::isFrameDataComplete()
//{
//  return true;
//}
//
//void NaoProvider::waitForFrameData()
//{
//  if(theInstance)
//    theInstance->naoBody.wait();
//}

void NaoProvider::send(JointRequest &theJointRequest, JointCalibration &theJointCalibration)
{
//  DEBUG_RESPONSE("module:NaoProvider:lag100", SystemCall::sleep(100););
//  DEBUG_RESPONSE("module:NaoProvider:lag200", SystemCall::sleep(200););
//  DEBUG_RESPONSE("module:NaoProvider:lag300", SystemCall::sleep(200););
//  DEBUG_RESPONSE("module:NaoProvider:lag1000", SystemCall::sleep(1000););
//  DEBUG_RESPONSE("module:NaoProvider:lag3000", SystemCall::sleep(3000););
//  DEBUG_RESPONSE("module:NaoProvider:lag6000", SystemCall::sleep(6000););
//  DEBUG_RESPONSE("module:NaoProvider:segfault", *(char*)0 = 0;);
//
//  DEBUG_RESPONSE("module:NaoProvider:ClippingInfo",
//  {
//    for(int i = 0; i < JointData::numOfJoints; ++i)
//    {
//      if(i == JointData::RHipYawPitch) // missing on Nao
//        ++i;
//
//      if(theJointRequest.angles[i] != JointData::off)
//      {
//        if(theJointRequest.angles[i] > theJointCalibration.joints[i].maxAngle)
//        {
//          if(clippedLastFrame[i] != theJointCalibration.joints[i].maxAngle)
//          {
//            char tmp[64];
//            sprintf(tmp, "warning: clipped joint %s at %.03f, requested %.03f.", JointData::getName((JointData::Joint)i), toDegrees(theJointCalibration.joints[i].maxAngle), toDegrees(theJointRequest.angles[i]));
//            OUTPUT(idText, text, tmp);
//            clippedLastFrame[i] = theJointCalibration.joints[i].maxAngle;
//          }
//        }
//        else if(theJointRequest.angles[i] < theJointCalibration.joints[i].minAngle)
//        {
//          if(clippedLastFrame[i] != theJointCalibration.joints[i].minAngle)
//          {
//            char tmp[64];
//            sprintf(tmp, "warning: clipped joint %s at %.04f, requested %.03f.", JointData::getName((JointData::Joint)i), toDegrees(theJointCalibration.joints[i].minAngle), toDegrees(theJointRequest.angles[i]));
//            OUTPUT(idText, text, tmp);
//            clippedLastFrame[i] = theJointCalibration.joints[i].minAngle;
//          }
//        }
//        else
//          clippedLastFrame[i] = JointData::off;
//      }
//    }
//  });
//
//#ifdef MEASURE_DELAY
//  OutTextFile stream("delay.log", true);
//  stream << "jointRequest";
//  stream << theJointRequest.angles[JointData::LHipPitch];
//  stream << theJointRequest.angles[JointData::LKneePitch];
//  stream << theJointRequest.angles[JointData::LAnklePitch];
//  stream << endl;
//#endif

//  naoBody.openActuators(actuators);
  int j = 0;
  int headYawPositionActuator = 0;
  int headYawHardnessActuator = int(JointData::numOfJoints) - 1;

  for(int i = 0; i < JointData::numOfJoints; ++i)
  {
    if(i == JointData::RHipYawPitch) // missing on Nao
      ++i;

    if(theJointRequest.angles[i] == JointData::off)
    {
      actuators[j] = 0.0f;
      actuators[j + headYawHardnessActuator] = 0.0f; // hardness
    }
    else
    {
      actuators[j] = (theJointRequest.angles[i] + theJointCalibration.joints[i].offset) * float(theJointCalibration.joints[i].sign);
      actuators[j + headYawHardnessActuator] = float(theJointRequest.jointHardness.hardness[i]) / 100.f;
    }
    ++j;
  }
  j += headYawHardnessActuator;
//  ASSERT(j == faceLedRedLeft0DegActuator);

//  const LEDRequest& ledRequest(theLEDRequest);
  //checkBoardState(ledRequest);

//  bool on = (theJointData.timeStamp / 50 & 8) != 0;
//  bool fastOn = (theJointData.timeStamp / 10 & 8) != 0;
//  for(int i = 0; i < LEDRequest::numOfLEDs; ++i)
//    actuators[j++] = (ledRequest.ledStates[i] == LEDRequest::on ||
//                      (ledRequest.ledStates[i] == LEDRequest::blinking && on) ||
//                      (ledRequest.ledStates[i] == LEDRequest::fastBlinking && fastOn))
//                     ? 1.0f : (ledRequest.ledStates[i] == LEDRequest::half ? 0.5f : 0.0f);

  // set ultrasound mode
//  MODIFY("module:NaoProvider:usSettings", usSettings);
//  if(theJointData.timeStamp - lastUsSendTime >= usSettings.sendInterval - 5)
//  {
//    if(theJointData.timeStamp - lastUsSwitchTime >= usSettings.switchInterval - 5)
//    {
//      currentUsMode = (currentUsMode + 1) % usSettings.modes.size();
//      lastUsSwitchTime = theJointData.timeStamp;
//    }
//    actuators[usActuator] = usSettings.modes[currentUsMode] + 4.f;
//    lastUsSendTime = theJointData.timeStamp;
//  }
//  else
//    actuators[usActuator] = -1.f;


//  naoBody.closeActuators();
}

void NaoProvider::update(
  JointData& jointData,
  const JointCalibration &theJointCalibration,
  SensorData& sensorData,
  const SensorCalibration &theSensorCalibration,
  FrameInfo& frameInfo)
{
  frameInfo.cycleTime = 0.01f;
  frameInfo.time = jointData.timeStamp = sensorData.timeStamp = SystemCall::getCurrentSystemTime();

  int j = 0;
  for(int i = 0; i < JointData::numOfJoints; ++i)
  {
    if(i == JointData::RHipYawPitch)
    {
      jointData.angles[i] = jointData.angles[JointData::LHipYawPitch];
      sensorData.currents[i] = sensorData.currents[JointData::LHipYawPitch];
      sensorData.temperatures[i] = sensorData.temperatures[JointData::LHipYawPitch];
    }
    else
    {
      jointData.angles[i] = sensors[j++] * (float)theJointCalibration.joints[i].sign - theJointCalibration.joints[i].offset;
      sensorData.currents[i] = short(1000 * sensors[j++]);
      sensorData.temperatures[i] = (unsigned char) sensors[j++];
    }
  }

#ifdef MEASURE_DELAY
  OutTextFile stream("delay.log", true);
  stream << "timestamp" << SystemCall::getCurrentSystemTime();
  stream << "jointData";
  stream << jointData.angles[JointData::LHipPitch];
  stream << jointData.angles[JointData::LKneePitch];
  stream << jointData.angles[JointData::LAnklePitch];
#endif

  float currentGyroRef = 0.f;
  for(int i = 0; i < SensorData::numOfSensors; ++i)
  {
    if(i == SensorData::gyroZ)
      currentGyroRef = sensors[j++];
    else
      sensorData.data[i] = sensors[j++];
  }

  sensorData.data[SensorData::gyroX] *= theSensorCalibration.gyroXGain / 1600;
  sensorData.data[SensorData::gyroY] *= theSensorCalibration.gyroYGain / 1600;
  sensorData.data[SensorData::accX] *= theSensorCalibration.accXGain;
  sensorData.data[SensorData::accX] += theSensorCalibration.accXOffset;
  sensorData.data[SensorData::accY] *= theSensorCalibration.accYGain;
  sensorData.data[SensorData::accY] += theSensorCalibration.accYOffset;
  sensorData.data[SensorData::accZ] *= theSensorCalibration.accZGain;
  sensorData.data[SensorData::accZ] += theSensorCalibration.accZOffset;

  sensorData.data[SensorData::fsrLFL] = /*sensorData.data[SensorData::fsrLFL] != 0.f ?*/ ((sensorData.data[SensorData::fsrLFL] + theSensorCalibration.fsrLFLOffset) * theSensorCalibration.fsrLFLGain) /*: SensorData::off*/;
  sensorData.data[SensorData::fsrLFR] = /*sensorData.data[SensorData::fsrLFR] != 0.f ?*/ ((sensorData.data[SensorData::fsrLFR] + theSensorCalibration.fsrLFROffset) * theSensorCalibration.fsrLFRGain) /*: SensorData::off*/;
  sensorData.data[SensorData::fsrLBL] = /*sensorData.data[SensorData::fsrLBL] != 0.f ?*/ ((sensorData.data[SensorData::fsrLBL] + theSensorCalibration.fsrLBLOffset) * theSensorCalibration.fsrLBLGain) /*: SensorData::off*/;
  sensorData.data[SensorData::fsrLBR] = /*sensorData.data[SensorData::fsrLBR] != 0.f ?*/ ((sensorData.data[SensorData::fsrLBR] + theSensorCalibration.fsrLBROffset) * theSensorCalibration.fsrLBRGain) /*: SensorData::off*/;
  sensorData.data[SensorData::fsrRFL] = /*sensorData.data[SensorData::fsrRFL] != 0.f ?*/ ((sensorData.data[SensorData::fsrRFL] + theSensorCalibration.fsrRFLOffset) * theSensorCalibration.fsrRFLGain) /*: SensorData::off*/;
  sensorData.data[SensorData::fsrRFR] = /*sensorData.data[SensorData::fsrRFR] != 0.f ?*/ ((sensorData.data[SensorData::fsrRFR] + theSensorCalibration.fsrRFROffset) * theSensorCalibration.fsrRFRGain) /*: SensorData::off*/;
  sensorData.data[SensorData::fsrRBL] = /*sensorData.data[SensorData::fsrRBL] != 0.f ?*/ ((sensorData.data[SensorData::fsrRBL] + theSensorCalibration.fsrRBLOffset) * theSensorCalibration.fsrRBLGain) /*: SensorData::off*/;
  sensorData.data[SensorData::fsrRBR] = /*sensorData.data[SensorData::fsrRBR] != 0.f ?*/ ((sensorData.data[SensorData::fsrRBR] + theSensorCalibration.fsrRBROffset) * theSensorCalibration.fsrRBRGain) /*: SensorData::off*/;

#ifdef MEASURE_DELAY
  stream << "sensorData";
  stream << sensorData.data[SensorData::gyroX] << sensorData.data[SensorData::gyroY] << sensorData.data[SensorData::accX] << sensorData.data[SensorData::accY] << sensorData.data[SensorData::accZ];
#endif

//  for(int i = 0; i < KeyStates::numOfKeys; ++i)
//    keyStates.pressed[i] = sensors[j++] != 0;
//
//  for(int i = 0; i < BoardInfo::numOfBoards; ++i)
//  {
//    boardInfo.ack[i] = (int) sensors[j++];
//    boardInfo.nack[i] = (int) sensors[j++];
//    boardInfo.error[i] = (int) sensors[j++];
//  }
//
//  // modify internal data structure, so checkBoardState is influenced as well
//  MODIFY("representation:BoardInfo", boardInfo);

  // ultasound
//  if(theJointData.timeStamp - lastUsSwitchTime >= usSettings.ignoreAfterSwitchInterval - 5)
//  {
//    if(theJointData.timeStamp - lastUsReadTime >= usSettings.sendInterval - 5)
//    {
//      lastUsReadTime = theJointData.timeStamp;
//      leftUsSensor = sensors[lUsSensor];
//      rightUsSensor = sensors[rUsSensor];
//      leftUsSensor = leftUsSensor == 0.f ? 3000.f : (leftUsSensor * 1000.f);
//      rightUsSensor = rightUsSensor == 0.f ? 3000.f : (rightUsSensor * 1000.f);
//      usActuatorMode = SensorData::UsActuatorMode(int(usSettings.modes[currentUsMode]));
//    }
//  }
//  sensorData.data[SensorData::usL] = leftUsSensor;
//  sensorData.data[SensorData::usR] = rightUsSensor;
//  sensorData.usTimeStamp = lastUsReadTime;
//  sensorData.usActuatorMode = usActuatorMode;

//  PLOT("module:NaoProvider:usLeft", leftUsSensor);
//  PLOT("module:NaoProvider:usRight", rightUsSensor);
//  PLOT("module:NaoProvider:usLeft2", sensors[lUsSensor] * 1000.f);
//  PLOT("module:NaoProvider:usRight2", sensors[rUsSensor] * 1000.f);
//
//#ifndef RELEASE
//  JointDataDeg jointDataDeg(jointData);
//#endif
//  MODIFY("representation:JointDataDeg", jointDataDeg);
}

//void NaoProvider::checkBoardState(LEDRequest& ledRequest)
//{
//  const static LEDRequest::LED leds[BoardInfo::numOfBoards] =
//  {
//    LEDRequest::earsLeft72Deg, // chestBoard
//    LEDRequest::earsRight72Deg, // battery
//    LEDRequest::earsLeft108Deg, // usBoard
//    LEDRequest::earsRight108Deg, // inertialSensor
//    LEDRequest::earsLeft324Deg, // headBoard
//    LEDRequest::faceRightBlue0Deg, // earLeds
//    LEDRequest::earsRight324Deg, // faceBoard
//    LEDRequest::earsLeft0Deg, // leftShoulderBoard
//    LEDRequest::earsLeft36Deg, //leftArmBoard
//    LEDRequest::earsRight0Deg, // rightShoulderBoard
//    LEDRequest::earsRight36Deg, // rightArmBoard
//    LEDRequest::earsLeft288Deg, // leftHipBoard
//    LEDRequest::earsLeft252Deg, //leftThighBoard
//    LEDRequest::earsLeft216Deg, // leftShinBoard
//    LEDRequest::earsLeft180Deg, // leftFootBoard
//    LEDRequest::earsRight288Deg, // rightHipBoard
//    LEDRequest::earsRight252Deg, // rightThighBoard
//    LEDRequest::earsRight216Deg, // rightShinBoard
//    LEDRequest::earsRight180Deg // rightFootBoard
//  };
//
//  unsigned now = SystemCall::getCurrentSystemTime();
//  bool camera = now - theCognitionFrameInfo.time < 2000,
//       error = !camera;
//
//  int i;
//  for(i = 0; i < BoardInfo::numOfBoards; ++i)
//  {
//    if(lastAck[i] != boardInfo.ack[i])
//    {
//      lastTimeWhenAck[i] = now;
//      lastAck[i] = boardInfo.ack[i];
//    }
//    if(now - lastTimeWhenAck[i] > 2000 || (boardInfo.error[i] && (boardInfo.error[i] & 0xf0) != 0xd0))
//      error = true;
//  }
//
//  if(error)
//  {
//    for(i = 0; i < LEDRequest::chestRed; ++i)
//      ledRequest.ledStates[i] = LEDRequest::off;
//
//    for(i = 0; i < BoardInfo::numOfBoards; ++i)
//      if(now - lastTimeWhenAck[i] > 2000 || (boardInfo.error[i] && (boardInfo.error[i] & 0xf0) != 0xd0))
//        ledRequest.ledStates[leds[i]] = LEDRequest::on;
//      else
//        ledRequest.ledStates[leds[i]] = LEDRequest::blinking;
//
//    for(i = LEDRequest::faceLeftBlue0Deg; i < LEDRequest::faceRightRed0Deg; ++i)
//      ledRequest.ledStates[i] = camera ? LEDRequest::off : LEDRequest::blinking;
//
//    bool ear = ledRequest.ledStates[LEDRequest::faceRightBlue0Deg] != LEDRequest::on;
//    for(i = LEDRequest::faceRightBlue0Deg; i < LEDRequest::LEDRequest::earsLeft0Deg; ++i)
//      ledRequest.ledStates[i] = ear ? LEDRequest::off : LEDRequest::blinking;
//  }
//}

//void NaoProvider::finishFrame()
//{
//  if(theInstance)
//    theInstance->send();
//}
