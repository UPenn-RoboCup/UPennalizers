/**
* @file GroundContactDetector.h
*
* Declaration of module GroundContactDetector.
*
* @author <a href="mailto:fynn@informatik.uni-bremen.de">Fynn Feldpausch</a>
*/

#pragma once

//#include "Tools/Module/Module.h"
#include "Tools/RingBufferWithSum.h"
#include "Representations/Infrastructure/SensorData.h"
#include "Representations/Infrastructure/FrameInfo.h"
// #include "Representations/Infrastructure/RobotInfo.h"
#include "Representations/Sensing/GroundContactState.h"
#include "Representations/MotionControl/MotionInfo.h"
#include "Representations/MotionControl/MotionRequest.h"

//MODULE(GroundContactDetector)
//  REQUIRES(SensorData)
//  REQUIRES(FrameInfo)
//  REQUIRES(MotionRequest)
//  USES(MotionInfo)
//  PROVIDES_WITH_MODIFY(GroundContactState)
//END_MODULE

/**
* @class GroundContactDetector
* A module for sensor data filtering.
*/
class GroundContactDetector //: public GroundContactDetectorBase
{
public:
  /** Default constructor. */
  GroundContactDetector();

  /**
  * Updates the GroundContactState representation.
  * @param groundContactState The ground contact representation which is updated by this module.
  */
  void update(GroundContactState& groundContactState,
              const SensorData& theSensorData,
              const FrameInfo& theFrameInfo,
              const MotionRequest& theMotionRequest,
              const MotionInfo& theMotionInfo 
              );

private:
  /**
  * A collection of parameters for the ground contact detector.
  */
  class Parameters : public Streamable
  {
  public:
    bool forceContact;         // true -> always ground contact
    float fsrLimit;            // higher fsr values will be ignored
    float fsrThreshold;        // threshold for fsr contact
    float loadThreshold;       // threshold for load contact
    float contactThreshold;    // threshold for safe ground contact
    float noContactThreshold;  // threshold for safe no ground contact
    int safeContactTime;       // minimum continuous contact to be safe in ms
    int safeNoContactTime;     // minimum continuous non-contact to be safely lifted up in ms

  private:
    /**
    * The method makes the object streamable.
    * @param in The stream from which the object is read.
    * @param out The stream to which the object is written.
    */
    virtual void serialize(In* in, Out* out)
    {
      STREAM_REGISTER_BEGIN();
      STREAM(forceContact);
      STREAM(fsrLimit);
      STREAM(fsrThreshold);
      STREAM(loadThreshold);
      STREAM(contactThreshold);
      STREAM(noContactThreshold);
      STREAM(safeContactTime);
      STREAM(safeNoContactTime);
      STREAM_REGISTER_FINISH();
    }
  };

  Parameters p;

  bool contact;
  bool lastContact;
  unsigned int contactStartTime;
  unsigned int noContactStartTime;
  static const int BUFFER_SIZE = 25;
  RingBufferWithSum<float, BUFFER_SIZE> confidenceContactBuffer;
  RingBufferWithSum<float, BUFFER_SIZE> confidenceNoContactBuffer;

  struct ContactState
  {
    bool contact;
    float confidence;
  };

  void init();

  /**
  * Checks the loads in respect of the ground contact.
  */
  struct ContactState checkLoad(const SensorData& theSensorData);

  /**
  * Checks the FSRs in respect of the ground contact.
  * @param left Check the FSRs of the left or right foot?
  */
  struct ContactState checkFsr(bool left, const SensorData& theSensorData);
};
