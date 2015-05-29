/**
* @file WalkingEngine.h
* Declaration a module that creates the walking motions
* @author Colin Graf
*/

#pragma once

//#include "Tools/Module/Module.h"
//#include "Modules/Infrastructure/NaoProvider.h"
#include "MotionSelector.h"
#include "Modules/Sensing/JointFilter.h"
#include "Modules/Sensing/RobotModelProvider.h"
#include "Modules/Sensing/TorsoMatrixProvider.h"
#include "Modules/Sensing/InertiaSensorInspector.h"
#include "Modules/Sensing/InertiaSensorCalibrator.h"
#include "Modules/Sensing/InertiaSensorFilter.h"
#include "Modules/Sensing/SensorFilter.h"
#include "Modules/Sensing/FallDownStateDetector.h"
#include "Modules/Sensing/GroundContactDetector.h"
#include "Representations/Configuration/RobotDimensions.h"
#include "Representations/Configuration/MassCalibration.h"
#include "Representations/Configuration/JointCalibration.h"
#include "Representations/Configuration/SensorCalibration.h"
#include "Representations/Configuration/DamageConfiguration.h"
#include "Representations/Infrastructure/FrameInfo.h"
//#include "Representations/Infrastructure/KeyStates.h"
#include "Representations/Infrastructure/SensorData.h"
#include "Representations/Sensing/RobotModel.h"
#include "Representations/Sensing/TorsoMatrix.h"
//#include "Representations/Modeling/FallDownState.h"
#include "Representations/MotionControl/MotionSelection.h"
#include "Representations/MotionControl/MotionRequest.h"
#include "Representations/MotionControl/WalkingEngineStandOutput.h"
#include "Representations/MotionControl/WalkingEngineOutput.h"
//#include "Representations/MotionControl/HeadJointRequest.h"
#include "Representations/MotionControl/OdometryData.h"
#include "Representations/Sensing/GroundContactState.h"
#include "Tools/RingBuffer.h"
#include "Tools/RingBufferWithSum.h"
#include "Tools/Math/Matrix.h"
//#include "Platform/SystemCall.h"
//#include "Tools/Optimization/ParticleSwarm.h"
#include "WalkingEngineKick.h"

//MODULE(WalkingEngine)
//  REQUIRES(MotionSelection)
//  REQUIRES(MotionRequest)
//  REQUIRES(RobotModel)
//  REQUIRES(RobotDimensions)
//  REQUIRES(MassCalibration)
//  REQUIRES(HeadJointRequest)
//  REQUIRES(FrameInfo)
//  REQUIRES(KeyStates)
//  REQUIRES(TorsoMatrix)
//  REQUIRES(GroundContactState)
//  REQUIRES(FallDownState)
//  REQUIRES(JointCalibration)
//  REQUIRES(DamageConfiguration)
//  REQUIRES(SensorData)
//  USES(OdometryData)
//  PROVIDES_WITH_MODIFY(WalkingEngineOutput)
//  REQUIRES(WalkingEngineOutput)
//  PROVIDES_WITH_MODIFY(WalkingEngineStandOutput)
//END_MODULE

class WalkingEngine //: public WalkingEngineBase
{
public:
  /**
  * Default constructor
  */
  WalkingEngine();

  /*
  * Destructor
  */
  ~WalkingEngine() {}//theInstance = 0;}

private:

  static const int INSTABILITY_THRESH = 500;

  class PIDCorrector
  {
  public:
    class Parameters : public Streamable
    {
    public:
      float p;
      float i;
      float d;
      float max;

      Parameters() : p(0.f), i(0.f), d(0.f), max(0.f) {}

      Parameters(float p, float i, float d, float max) : p(p), i(i), d(d), max(max) {}

    private:
      virtual void serialize(In* in, Out* out)
      {
        STREAM_REGISTER_BEGIN();
        STREAM(p);
        STREAM(i);
        STREAM(d);
        STREAM(max);
        STREAM_REGISTER_FINISH();
      }
    };

    PIDCorrector() : sum(0.f), error(0.f) {}

    float getCorrection(float measuredError, float deltaTime, float measurementDelay, const Parameters& parameters)
    {
      float error = -measuredError;
      //int max = std::min(int(measurementDelay / 10.f + 0.5f), corrections.getNumberOfEntries());
      //for(int i = 0; i < max; ++i)
      //error -= corrections.getEntry(i);
      sum += error * deltaTime * parameters.i;
      float correction = error * parameters.p + sum + (error - this->error) / deltaTime * parameters.d;
      this->error = error;
      //corrections.add(correction);
      if(correction > parameters.max)
        correction = parameters.max;
      else if(correction < -parameters.max)
        correction = -parameters.max;
      return correction;
    }

  private:
    float sum;
    float error;
    //RingBuffer<float, 10> corrections;
  };

  class PhaseParameters : public Streamable
  {
  public:
    float start;
    float duration;

    PhaseParameters() : start(0.f), duration(1.f) {}

  private:
    virtual void serialize(In* in, Out* out)
    {
      STREAM_REGISTER_BEGIN();
      STREAM(start);
      STREAM(duration);
      STREAM_REGISTER_FINISH();
    }
  };

  /**
  * A collection of walking engine parameters
  */
  class Parameters : public Streamable
  {
  public:
    ENUM(FadeInShape,
      sine,
      sqr
    );

    ENUM(MeasurementMode,
      torsoMatrix,
      robotModel
    );

    ENUM(ObserverErrorMode,
      direct,
      indirect,
      average,
      mixed
    );

    /** Default constructor */
    Parameters() {}

    float standBikeRefX;
    float standStandbyRefX;
    Vector3<> standComPosition;
    float standBodyTilt;
    Vector2<> standArmJointAngles;
    int standHardnessAnklePitch;
    int standHardnessAnkleRoll;

    float walkRefX;
    float walkRefXAtFullSpeedX;
    float walkRefY;
    float walkRefYAtFullSpeedX;
    float walkRefYAtFullSpeedY;
    float walkStepDuration;
    float walkStepDurationAtFullSpeedX;
    float walkStepDurationAtFullSpeedY;
    Vector2<> walkHeight;
    float walkArmRotation;
    Range<> walkRefXSoftLimit;
    Range<> walkRefXLimit;
    Range<> walkRefYLimit;
    Range<> walkRefYLimitAtFullSpeedX;
    PhaseParameters walkMovePhase;
    PhaseParameters walkLiftPhase;
    Vector3<> walkLiftOffset;
    float walkLiftOffsetJerk;
    Vector3<> walkLiftOffsetAtFullSpeedY;
    Vector3<> walkLiftRotation;
    Vector3<> walkAntiLiftOffset;
    Vector3<> walkAntiLiftOffsetAtFullSpeedY;
    float walkComBodyRotation;
    FadeInShape walkFadeInShape;

    Vector3<> kickComPosition;
    float kickX0Y;
    Vector2<> kickHeight;

    Pose2D speedMax;
    Pose2D speedMaxMin;
    float speedMaxBackwards;
    Pose2D speedMaxChange;

    bool balance;
    Vector3<> balanceMinError;
    Vector3<> balanceMaxError;
    Vector3<PIDCorrector::Parameters> balanceCom;
    Vector2<PIDCorrector::Parameters> balanceBodyRotation;
    Vector2<> balanceStepSize;
    Vector2<> balanceStepSizeWhenInstable;
    Vector2<> balanceStepSizeWhenPedantic;
    float balanceStepSizeInterpolation;

    float stabilizerOnThreshold;
    float stabilizerOffThreshold;
    int stabilizerDelay;

    MeasurementMode observerMeasurementMode;
    float observerMeasurementDelay;
    ObserverErrorMode observerErrorMode;
    Vector4f observerProcessDeviation;
    Vector2f observerMeasurementDeviation;
    Vector2f observerMeasurementDeviationAtFullSpeedX;
    Vector2f observerMeasurementDeviationWhenInstable;

    bool odometryUseTorsoMatrix;
    Pose2D odometryScale;
    Pose2D odometryUpcomingScale;
    Pose2D odometryUpcomingOffset;

    // computed values
    RotationMatrix standBodyRotation;
    Vector2<> kickK;
    Vector2<> walkK;
    float te;
    float teAtFullSpeedX;
    float teAtFullSpeedY;

    void computeContants()
    {
      const float g = 9806.65f;;
      walkK.x = sqrtf(g / walkHeight.x);
      walkK.y = sqrtf(g / walkHeight.y);
      kickK.x = sqrtf(g / kickHeight.x);
      kickK.y = sqrtf(g / kickHeight.y);
      te = walkStepDuration * (0.001f * 0.25f);
      teAtFullSpeedX = walkStepDurationAtFullSpeedX * (0.001f * 0.25f);
      teAtFullSpeedY = walkStepDurationAtFullSpeedY * (0.001f * 0.25f);
      standBodyRotation = RotationMatrix(Vector3<>(0.f, standBodyTilt, 0.f));
    }

  private:
    /**
    * Makes the object streamable
    * @param in The stream from which the object is read
    * @param out The stream to which the object is written.
    */
    void serialize(In* in, Out* out)
    {
      STREAM_REGISTER_BEGIN();

      STREAM(standBikeRefX);
      STREAM(standStandbyRefX);
      STREAM(standComPosition);
      STREAM(standBodyTilt);
      STREAM(standArmJointAngles);
      STREAM(standHardnessAnklePitch);
      STREAM(standHardnessAnkleRoll);

      STREAM(walkRefX);
      STREAM(walkRefXAtFullSpeedX);
      STREAM(walkRefY);
      STREAM(walkRefYAtFullSpeedX);
      STREAM(walkRefYAtFullSpeedY);
      STREAM(walkStepDuration);
      STREAM(walkStepDurationAtFullSpeedX);
      STREAM(walkStepDurationAtFullSpeedY);
      STREAM(walkHeight);
      STREAM(walkArmRotation);
      STREAM(walkRefXSoftLimit);
      STREAM(walkRefXLimit);
      STREAM(walkRefYLimit);
      STREAM(walkRefYLimitAtFullSpeedX);
      STREAM(walkMovePhase);
      STREAM(walkLiftPhase);
      STREAM(walkLiftOffset);
      STREAM(walkLiftOffsetJerk);
      STREAM(walkLiftOffsetAtFullSpeedY);
      STREAM(walkLiftRotation);
      STREAM(walkAntiLiftOffset);
      STREAM(walkAntiLiftOffsetAtFullSpeedY);
      STREAM(walkComBodyRotation);
      STREAM(walkFadeInShape);

      STREAM(kickComPosition);
      STREAM(kickX0Y);
      STREAM(kickHeight);

      STREAM(speedMax);
      STREAM(speedMaxMin);
      STREAM(speedMaxBackwards);
      STREAM(speedMaxChange);

      STREAM(observerMeasurementMode);
      STREAM(observerMeasurementDelay);
      STREAM(observerErrorMode);
      STREAM(observerProcessDeviation);
      STREAM(observerMeasurementDeviation);
      STREAM(observerMeasurementDeviationAtFullSpeedX);
      STREAM(observerMeasurementDeviationWhenInstable);

      STREAM(balance);
      STREAM(balanceMinError);
      STREAM(balanceMaxError);
      STREAM(balanceCom);
      STREAM(balanceBodyRotation);
      STREAM(balanceStepSize);
      STREAM(balanceStepSizeWhenInstable);
      STREAM(balanceStepSizeWhenPedantic);
      STREAM(balanceStepSizeInterpolation);

      STREAM(stabilizerOnThreshold);
      STREAM(stabilizerOffThreshold);
      STREAM(stabilizerDelay)

      STREAM(odometryUseTorsoMatrix);
      STREAM(odometryScale);
      STREAM(odometryUpcomingScale);
      STREAM(odometryUpcomingOffset);

      STREAM_REGISTER_FINISH();

      if(in)
        computeContants();
    }
  };

  class LegStance
  {
  public:
    Pose3D leftOriginToFoot;
    Pose3D rightOriginToFoot;
    Vector3<> leftOriginToCom;
    Vector3<> rightOriginToCom;
  };

  class ArmAndHeadStance
  {
  public:
    float headJointAngles[2];
    float leftArmJointAngles[4];
    float rightArmJointAngles[4];
  };

  class Stance : public LegStance, public ArmAndHeadStance {};

  ENUM(MotionType,
    stand,
    standLeft,
    standRight,
    stepping
  );

  ENUM(StepType,
    normal,
    unknown,
    fromStand,
    toStand,
    fromStandLeft,
    toStandLeft,
    fromStandRight,
    toStandRight
  );

  class StepSize
  {
  public:
    Vector3<> translation;
    float rotation;

    StepSize() : rotation(0.f) {}

    StepSize(float rotation, float x, float y) : translation(x, y, 0.f), rotation(rotation) {}

    StepSize(const StepSize& other) : translation(other.translation), rotation(other.rotation) {}

    StepSize& operator+=(const StepSize& other)
    {
      translation += other.translation;
      rotation += other.rotation;
      return *this;
    }

    StepSize& operator-=(const StepSize& other)
    {
      translation -= other.translation;
      rotation -= other.rotation;
      return *this;
    }

    StepSize& operator*=(float factor)
    {
      translation *= factor;
      rotation *= factor;
      return *this;
    }

    StepSize operator+(const StepSize& other) const
    {
      return StepSize(*this) += other;
    }

    StepSize operator-(const StepSize& other) const
    {
      return StepSize(*this) -= other;
    }

    StepSize operator*(float factor) const
    {
      return StepSize(*this) *= factor;
    }

    operator Pose2D() const
    {
      return Pose2D(rotation, translation.x, translation.y);
    }
  };

  class PendulumParameters
  {
  public:
    Vector2<> x0; /**< pendulum position at t = 0 */
    Vector2<> xv0; /**< pendulum velocity at t = 0 */
    Vector2<> r; /**< origin to ref */
    Vector2<> c;
    Vector2<> k; /**< sqrt(g / h) */
    float te; /**< end of pendulum phase */
    float tb; /**< begin of pendulum phase */
    StepSize s;
    Vector3<> l; /**< lift offset */
    Vector3<> lRotation; /**< lift rotation */
    Vector3<> al; /**< anti lift offset */
    StepType type;
    Vector2<> xtb; /**< pendulum position at t = tb */
    Vector2<> xvtb; /**< pendulum velocity at t = tb */
    Range<> sXLimit;
    Range<> rXLimit;
    Range<> rYLimit;
    WalkRequest::KickType kickType;
    float originalRX;
    PendulumParameters() : type(unknown) {}
  };

  ENUM(SupportLeg,
    left,
    right
  );

  class PendulumPlayer : public PendulumParameters
  {
  public:
    WalkingEngine* walkingEngine;
    SupportLeg supportLeg;
    bool active;
    bool launching;
    float t; /**< current time */
    PendulumParameters next;

    PendulumPlayer() : walkingEngine(0), active(false) {}

    void seek(float deltaT);
    inline bool isActive() const {return active;}
    inline bool isLaunching() const {return launching;}
    void getStance(LegStance& stance, float* leftArmAngle, float* rightArmAngle, StepSize* stepOffset) const;

    float smoothShape(float r) const;

  protected:
    void generateNextStepSize();
    void computeSwapTimes(float t, float xt, float xvt, float errory);
    void computeRefZmp(float t, float xt, float xvt, float errorx);
  };

  class ObservedPendulumPlayer : public PendulumPlayer
  {
  public:
    void init(StepType stepType, float t, SupportLeg supportLeg, const Vector2<>& r, const Vector2<>& x0, const Vector2<>& k, float deltaTime);
    void applyCorrection(const Vector3<>& leftError, const Vector3<>& rightError, float deltaTime);

  private:
    Matrix4x4f cov;
  };

  class KickPlayer
  {
  public:
    KickPlayer();

    void init(WalkRequest::KickType type, const Vector2<>& ballPosition, const Vector2<>& target);
    void seek(float deltaT);
    float getLength() const;
    float getCurrentPosition() const;
    void apply(Stance& stance);
    void stop() {kick = 0;};
    inline bool isActive() const {return kick ? true : false;}
    inline WalkRequest::KickType getType() const {return type;}
    void setParameters(const Vector2<>& ballPosition, const Vector2<>& target);
//    bool handleMessage(InMessage& message);

    inline bool isKickMirrored(WalkRequest::KickType type) const {return (type - 1) % 2 != 0;}
    bool isKickStandKick(WalkRequest::KickType type) const;
    void getKickStepSize(WalkRequest::KickType type, float& rotation, Vector3<>& translation) const;
    void getKickPreStepSize(WalkRequest::KickType type, float& rotation, Vector3<>& translation) const;
    float getKickDuration(WalkRequest::KickType type) const;
    float getKickRefX(WalkRequest::KickType type, float defaultValue) const;

  private:
    WalkingEngineKick* kick;
    bool mirrored;
    WalkRequest::KickType type;

    WalkingEngineKick kicks[(WalkRequest::numOfKickTypes - 1) / 2];
  };

//  PROCESS_WIDE_STORAGE_STATIC(WalkingEngine) theInstance;
  /**< Points to the only instance of this class in this process or is 0 if there is none */
  Parameters p; /**< The walking engine parameters */

  void init();

  public:
  void update( unsigned int t);

  //read from config
  JointCalibration theJointCalibration;
  SensorCalibration theSensorCalibration;
  MassCalibration theMassCalibration;
  RobotDimensions theRobotDimensions;
  HardnessData defaultHardnessData;

  //get these from robot using NaoProvider
  JointData theJointData;
  SensorData theSensorData;
  FrameInfo theFrameInfo;

  //filtered joint data from the joint filter
  FilteredJointData theFilteredJointData;
  JointFilter jointFilter;

  RobotModel theRobotModel;
  RobotModelProvider robotModelProvider;

  GroundContactDetector groundContactDetector;
  GroundContactState theGroundContactState;

  //removes faulty deviant sensor data
  InspectedInertiaSensorData theInspectedInertiaSensorData;
  InertiaSensorInspector inertiaSensorInspector;

  DamageConfiguration theDamageConfiguration;
  InertiaSensorData theInertiaSensorData;
  InertiaSensorCalibrator inertiaSensorCalibrator;

  OrientationData theOrientationData;
  InertiaSensorFilter inertiaSensorFilter;

  FilteredSensorData theFilteredSensorData;
  SensorFilter sensorFilter;

  FallDownState theFallDownState;
  FallDownStateDetector fallDownStateDetector;

  TorsoMatrix theTorsoMatrix;
  TorsoMatrixProvider torsoMatrixProvider;

  WalkingEngineOutput walkingEngineOutput;

  MotionSelector motionSelector;
  MotionSelection theMotionSelection;
  MotionInfo theMotionInfo;
  OdometryData theOdometryData;
  MotionRequest theMotionRequest;

  float joint_angles[JointData::numOfJoints];
  float joint_hardnesses[JointData::numOfJoints];

  SupportLeg getSupportLeg() const {
      return lastSupportLeg;
  }

  /**
  * The central update method to generate the walking motion
  * @param walkingEngineOutput The WalkingEngineOutput (mainly the resulting joint angles)
  */
  bool emergencyShutOff;
  MotionType currentMotionType;
  float currentRefX;
  Stance targetStance;
  JointRequest jointRequest;
  ObservedPendulumPlayer observedPendulumPlayer;
  PendulumPlayer pendulumPlayer;
  KickPlayer kickPlayer;

  /**
  * The update method to generate the standing stance
  * @param standOutput The WalkingEngineStandOutput (mainly the resulting joint angles)
  */
  void update(WalkingEngineStandOutput& standOutput) {(JointRequest&)standOutput = jointRequest;}

  // attributes used for module:WalkingEngine:testing debug response
  bool testing;
  unsigned int testingNextParameterSet;
  Pose2D testingStartOdometryData;
  unsigned int testingStartTime;
  RingBufferWithSum<float, 500> testingComErrorSqr;
  RingBufferWithSum<float, 500> testingComError;
  RingBufferWithSum<float, 500> testingCurrent;

  // attributes used for module:WalkingEngine:optimize debug response
//  ParticleSwarm optimizeOptimizer;
//  RingBufferWithSum<float, 300> optimizeFitness;
//  bool optimizeStarted;
//  unsigned int optimizeStartTime;
//  Parameters optimizeBestParameters;

  void updateMotionRequest();
  MotionType requestedMotionType;
  Pose2D requestedWalkTarget;
  Vector2<> balanceStepSize;

  void updateKickPlayer();

  void updateObservedPendulumPlayer();

  void computeMeasuredStance();
  Vector3<> measuredLeftToCom;
  Vector3<> measuredRightToCom;

  void computeExpectedStance();
  Vector3<> expectedLeftToCom;
  Vector3<> expectedRightToCom;
  StepSize stepOffset;

  void computeError();
  Vector3<> leftError;
  Vector3<> rightError;
  RingBufferWithSum<float, 100> instability;
  bool instable;
  unsigned beginOfStable;

  void updatePendulumPlayer();

  void generateTargetStance();
  RingBuffer<LegStance, 10> legStances;
  void getStandStance(LegStance& stance) const;

  void generateJointRequest();
  PIDCorrector leftControllerX, leftControllerY, leftControllerZ;
  PIDCorrector rightControllerX, rightControllerY, rightControllerZ;
  PIDCorrector bodyControllerX, bodyControllerY;
  Vector3<> bodyToCom;
  Vector3<> lastAverageComToAnkle;

  void generateOutput(WalkingEngineOutput& walkingEngineOutput);
  void generateDummyOutput(WalkingEngineOutput& walkingEngineOutput);

  void generateNextStepSize(SupportLeg nextSupportLeg, StepType lastStepType, WalkRequest::KickType lastKickType, PendulumParameters& next);
  SupportLeg lastNextSupportLeg;
  PendulumParameters nextPendulumParameters;
  Pose2D lastSelectedSpeed;
  WalkRequest::KickType lastExecutedWalkingKick;

  void computeOdometryOffset();
  Pose2D odometryOffset;
  Pose3D lastTorsoMatrix;
  SupportLeg lastSupportLeg;
  StepSize lastStepOffset;
  Pose2D upcomingOdometryOffset;
  bool upcomingOdometryOffsetValid;

  // Northern Bites hack for instability issues
  bool shouldReset;

  // Northern Bites hack for hand speed info
  void updateHandSpeeds();
  Vector2<> lastLeftHandPos, lastRightHandPos;
  float leftHandSpeed;
  float rightHandSpeed;
};
