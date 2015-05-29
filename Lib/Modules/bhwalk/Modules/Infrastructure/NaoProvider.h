/**
* @file Modules/Infrastructure/NaoProvider.h
* The file declares a module that provides information from the Nao via DCM.
* @author <a href="mailto:Thomas.Roefer@dfki.de">Thomas Röfer</a>
*/

#pragma once

//#include "Tools/Module/Module.h"
#include "Representations/Configuration/JointCalibration.h"
#include "Representations/Infrastructure/JointData.h"
#include "Representations/Infrastructure/SensorData.h"
#include "Representations/Configuration/SensorCalibration.h"
//#include "Representations/Infrastructure/KeyStates.h"
#include "Representations/Infrastructure/FrameInfo.h"
//#include "Representations/Infrastructure/LEDRequest.h"
//#include "Representations/Infrastructure/BoardInfo.h"
//#include "Platform/linux/NaoBody.h"

//MODULE(NaoProvider)
//  REQUIRES(JointCalibration)
//  REQUIRES(JointData)
//  REQUIRES(LEDRequest)
//  REQUIRES(SensorCalibration)
//  REQUIRES(CognitionFrameInfo)
//  PROVIDES_WITH_MODIFY_AND_OUTPUT(JointData)
//  PROVIDES_WITH_MODIFY_AND_OUTPUT(SensorData)
//  PROVIDES_WITH_MODIFY_AND_OUTPUT(KeyStates)
//  PROVIDES_WITH_MODIFY(FrameInfo)
//  PROVIDES_WITH_OUTPUT(BoardInfo) // MODIFY is also available, but defined elsewhere
//  USES(JointRequest) // Will be accessed in send()
//END_MODULE

/**
* @class NaoProvider
* A module that provides information from the Nao.
*/
class NaoProvider //: public NaoProviderBase
{

public:
//  PROCESS_WIDE_STORAGE_STATIC(NaoProvider) theInstance; /**< The only instance of this module. */

//  NaoBody naoBody;
//  SensorData sensorData; /**< The last sensor data received. */
//  KeyStates keyStates; /**< The last key states received. */
//  BoardInfo boardInfo; /**< Information about the connection to all boards of the robot. */
//  int lastAck[BoardInfo::numOfBoards];
//  unsigned lastTimeWhenAck[BoardInfo::numOfBoards];


//  class UsSettings : public Streamable
//  {
//  public:
//    unsigned int sendInterval;
//    unsigned int switchInterval;
//    unsigned int ignoreAfterSwitchInterval;
//    std::vector<float> modes;
//
//  private:
//    /**
//    * The method makes the object streamable.
//    * @param in The stream from which the object is read.
//    * @param out The stream to which the object is written.
//    */
//    virtual void serialize(In* in, Out* out)
//    {
//      STREAM_REGISTER_BEGIN();
//      STREAM(sendInterval);
//      STREAM(switchInterval);
//      STREAM(ignoreAfterSwitchInterval);
//      STREAM(modes);
//      STREAM_REGISTER_FINISH();
//    }
//  };

//  UsSettings usSettings; /**< Ultrasonic measurement mode settings. */
//  unsigned int lastUsSendTime; /**< The time when the last ultrasonic wave was send. */
//  unsigned int lastUsSwitchTime; /**< The time when the used transmitter was changed. */
//  unsigned int lastUsReadTime; /**< The time when the last measurement was read. */
//  unsigned int currentUsMode; /**< The index of the transmitter mode that is currently active. */

//  float leftUsSensor; /**< The last measurement read from the left sensor. */
//  float rightUsSensor; /**< The last measurement read from the right sensor. */
//  SensorData::UsActuatorMode usActuatorMode; /**< The transmitter mode that was active when the last measurements were read. */

//#ifndef RELEASE
//  float clippedLastFrame[JointData::numOfJoints]; /**< Array that indicates whether a certain joint value was clipped in the last frame (and what was the value)*/
//#endif

  void update(JointData& jointData, const JointCalibration &theJointCalibration,
              SensorData& sensorData, const SensorCalibration &theSensorCalibration,
              FrameInfo& frameInfo);
//  void update(SensorData& sensorData) {sensorData = this->sensorData;}
//  void update(KeyStates& keyStates) {keyStates = this->keyStates;}
//  void update(FrameInfo& frameInfo) {frameInfo.time = theJointData.timeStamp; frameInfo.cycleTime = theJointData.cycleTime;}
//  void update(BoardInfo& boardInfo) {boardInfo = this->boardInfo;}

  /**
  * The function sends a command to the Nao.
  */
  void send(JointRequest &theJointRequest, JointCalibration &theJointCalibration);

  /**
  * The method overwrites the LEDRequest to indicate problems with
  * Nao's microcontroller boards.
  * @param ledRequest The request that might be overwritten.
  */
//  void checkBoardState(LEDRequest& ledRequest);

public:
  /**
  * Constructor.
  */
  NaoProvider();

  /**
  * Destructor.
  */
  ~NaoProvider();

  // position and hardness for each joint
  float actuators[2*JointData::numOfJoints];
  // position, current, temperature for each joint and sensor information
  float sensors[3*JointData::numOfJoints + SensorData::numOfSensors];
  /**
  * The method is called by process Motion to send the requests to the Nao.
  */
//  static void finishFrame();
//
//  static bool isFrameDataComplete();
//
//  static void waitForFrameData();
};

