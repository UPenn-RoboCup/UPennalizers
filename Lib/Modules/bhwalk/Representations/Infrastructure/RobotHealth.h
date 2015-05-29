/**
* @file RobotHealth.h
* The file declares two classes to transport information about the current robot health
* @author <a href="mailto:timlaue@informatik.uni-bremen.de">Tim Laue</a>
*/

#pragma once

#include "Tools/Streams/Streamable.h"


/**
* @class MotionRobotHealth
* All information collected within motion process.
*/
class MotionRobotHealth : public Streamable
{
public:
  /**
  * The method makes the object streamable.
  * @param in The stream from which the object is read (if in != 0).
  * @param out The stream to which the object is written (if out != 0).
  */
  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM(motionFrameRate);
    STREAM_REGISTER_FINISH();
  }

  /** Constructor */
  MotionRobotHealth(): motionFrameRate(0.0f) {}

  float motionFrameRate;       /*< Frames per second within process "Motion" */
};


/**
* @class RobotHealth
* Full information about the robot.
*/
class RobotHealth : public MotionRobotHealth
{
private:
  /**
  * The method makes the object streamable.
  * @param in The stream from which the object is read (if in != 0).
  * @param out The stream to which the object is written (if out != 0).
  */
  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM_BASE(MotionRobotHealth);
    STREAM(cognitionFrameRate);
    STREAM(batteryLevel);
    STREAM(maxJointTemperature);
    STREAM(cpuTemperature);
    STREAM(boardTemperature);
    STREAM(load);
    STREAM(memoryUsage);
    STREAM(robotName);
    STREAM(ballPercepts);
    STREAM(linePercepts);
    STREAM(goalPercepts);
    STREAM(wlan);
    STREAM_REGISTER_FINISH();
  }

public:
  /** Constructor */
  RobotHealth() : cognitionFrameRate(0.0f), batteryLevel(0), maxJointTemperature(0), cpuTemperature(0), boardTemperature(0), memoryUsage(0), ballPercepts(0), linePercepts(0), goalPercepts(0), wlan(true)
  {
    load[0] = load[1] = load[2] = 0;
  }

  /** Assigning MotionRobotHealth
  * @param motionRobotHealth Information from the motion process
  */
  void operator=(const MotionRobotHealth& motionRobotHealth)
  {
    motionFrameRate = motionRobotHealth.motionFrameRate;
  }

  float cognitionFrameRate;    /*< Frames per second within process "Cognition" */
  unsigned char batteryLevel;               /*< Current batteryLevel of robot battery */
  unsigned char maxJointTemperature;        /*< Highest temperature of a robot actuator */
  unsigned char cpuTemperature; /**< The temperature of the cpu */
  unsigned char boardTemperature; /**< The temperature of the mainboard or northbridge, dunno */
  unsigned char load[3]; /*< load averages */
  unsigned char memoryUsage;    /*< Percentage of used memory */
  std::string robotName;       /*< For fancier drawing :-) */
  unsigned int ballPercepts; /**< A ball percept counter used to determine ball percepts per hour */
  unsigned int linePercepts; /**< A line percept counter used to determine line percepts per hour */
  unsigned int goalPercepts; /**< A goal percept counter used to determine goal percepts per hour */
  bool wlan; /**< Status of the wlan hardware. true: wlan hardware is ok. false: wlan hardware is (probably physically) broken. */
};
