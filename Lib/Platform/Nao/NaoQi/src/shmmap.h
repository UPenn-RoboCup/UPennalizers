#ifndef shmmap_h_DEFINED
#define shmmap_h_DEFINED

static const char sensorShmName[] = "/dcmSensor";
static const char actuatorShmName[] = "/dcmActuator";

int shmmap_open();
int shmmap_close();

// Sensors read from DCM
const int nJoint = 22;
const int nImu = 8;
const int nButton = 1;
const int nBumper = 4;
const int nFsr = 8;
const int nUs = 8;
const int nBattery = 2;

// Led actuators
const int nLedChest = 3;
const int nLedFootLeft = 3;
const int nLedFootRight = 3;
const int nLedFoot = nLedFootLeft + nLedFootRight;
const int nLedFaceLeft = 3*8;
const int nLedFaceRight = 3*8;
const int nLedFace = nLedFaceLeft + nLedFaceRight;
const int nLedEarsLeft = 10;
const int nLedEarsRight = 10;
const int nLedEars = nLedEarsLeft + nLedEarsRight;
const int nLedAll = nLedChest + nLedFoot + nLedFace + nLedEars;

extern struct sensorStruct {
  unsigned int count;
  unsigned int pad;

  double time;
  // Values read from DCM:
  double position[nJoint];
  double current[nJoint];
  double temperature[nJoint];
  double imu[nImu];
  double button[nButton];
  double bumper[nBumper];
  double fsr[nFsr];
  double us[nUs];
  double battery[nBattery];
} *pSensor;

extern struct actuatorStruct {
  unsigned int count;
  int mode;

  double time;
  double position[nJoint];
  double hardness[nJoint];
  double command[nJoint];
  double velocity[nJoint];
  double jointImuAngleX[nJoint];
  double jointImuAngleY[nJoint];

  double usActuator;
  
  double ledChest[nLedChest];
  double ledFootLeft[nLedFootLeft];
  double ledFootRight[nLedFootRight];
  double ledFaceLeft[nLedFaceLeft];
  double ledFaceRight[nLedFaceRight];
  double ledEarsLeft[nLedEarsLeft];
  double ledEarsRight[nLedEarsRight];
} *pActuator;

static const char* sensorNames[] = {
  // Position[nJoint]
  "Device/SubDeviceList/HeadYaw/Position/Sensor/Value",
  "Device/SubDeviceList/HeadPitch/Position/Sensor/Value",
  "Device/SubDeviceList/LShoulderPitch/Position/Sensor/Value",
  "Device/SubDeviceList/LShoulderRoll/Position/Sensor/Value",
  "Device/SubDeviceList/LElbowYaw/Position/Sensor/Value",
  "Device/SubDeviceList/LElbowRoll/Position/Sensor/Value",
  "Device/SubDeviceList/LHipYawPitch/Position/Sensor/Value",
  "Device/SubDeviceList/LHipRoll/Position/Sensor/Value",
  "Device/SubDeviceList/LHipPitch/Position/Sensor/Value",
  "Device/SubDeviceList/LKneePitch/Position/Sensor/Value",
  "Device/SubDeviceList/LAnklePitch/Position/Sensor/Value",
  "Device/SubDeviceList/LAnkleRoll/Position/Sensor/Value",
  "Device/SubDeviceList/RHipYawPitch/Position/Sensor/Value",
  "Device/SubDeviceList/RHipRoll/Position/Sensor/Value",
  "Device/SubDeviceList/RHipPitch/Position/Sensor/Value",
  "Device/SubDeviceList/RKneePitch/Position/Sensor/Value",
  "Device/SubDeviceList/RAnklePitch/Position/Sensor/Value",
  "Device/SubDeviceList/RAnkleRoll/Position/Sensor/Value",
  "Device/SubDeviceList/RShoulderPitch/Position/Sensor/Value",
  "Device/SubDeviceList/RShoulderRoll/Position/Sensor/Value",
  "Device/SubDeviceList/RElbowYaw/Position/Sensor/Value",
  "Device/SubDeviceList/RElbowRoll/Position/Sensor/Value",
  
  // Current[nJoint]
  "Device/SubDeviceList/HeadYaw/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/HeadPitch/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/LShoulderPitch/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/LShoulderRoll/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/LElbowYaw/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/LElbowRoll/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/LHipYawPitch/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/LHipRoll/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/LHipPitch/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/LKneePitch/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/LAnklePitch/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/LAnkleRoll/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/RHipYawPitch/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/RHipRoll/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/RHipPitch/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/RKneePitch/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/RAnklePitch/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/RAnkleRoll/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/RShoulderPitch/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/RShoulderRoll/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/RElbowYaw/ElectricCurrent/Sensor/Value",
  "Device/SubDeviceList/RElbowRoll/ElectricCurrent/Sensor/Value",

  // Temperature[nJoint]
  "Device/SubDeviceList/HeadYaw/Temperature/Sensor/Value",
  "Device/SubDeviceList/HeadPitch/Temperature/Sensor/Value",
  "Device/SubDeviceList/LShoulderPitch/Temperature/Sensor/Value",
  "Device/SubDeviceList/LShoulderRoll/Temperature/Sensor/Value",
  "Device/SubDeviceList/LElbowYaw/Temperature/Sensor/Value",
  "Device/SubDeviceList/LElbowRoll/Temperature/Sensor/Value",
  "Device/SubDeviceList/LHipYawPitch/Temperature/Sensor/Value",
  "Device/SubDeviceList/LHipRoll/Temperature/Sensor/Value",
  "Device/SubDeviceList/LHipPitch/Temperature/Sensor/Value",
  "Device/SubDeviceList/LKneePitch/Temperature/Sensor/Value",
  "Device/SubDeviceList/LAnklePitch/Temperature/Sensor/Value",
  "Device/SubDeviceList/LAnkleRoll/Temperature/Sensor/Value",
  "Device/SubDeviceList/RHipYawPitch/Temperature/Sensor/Value",
  "Device/SubDeviceList/RHipRoll/Temperature/Sensor/Value",
  "Device/SubDeviceList/RHipPitch/Temperature/Sensor/Value",
  "Device/SubDeviceList/RKneePitch/Temperature/Sensor/Value",
  "Device/SubDeviceList/RAnklePitch/Temperature/Sensor/Value",
  "Device/SubDeviceList/RAnkleRoll/Temperature/Sensor/Value",
  "Device/SubDeviceList/RShoulderPitch/Temperature/Sensor/Value",
  "Device/SubDeviceList/RShoulderRoll/Temperature/Sensor/Value",
  "Device/SubDeviceList/RElbowYaw/Temperature/Sensor/Value",
  "Device/SubDeviceList/RElbowRoll/Temperature/Sensor/Value",

  // Imu[nImu]
  "Device/SubDeviceList/InertialSensor/AngleX/Sensor/Value",
  "Device/SubDeviceList/InertialSensor/AngleY/Sensor/Value",
  "Device/SubDeviceList/InertialSensor/AccX/Sensor/Value",
  "Device/SubDeviceList/InertialSensor/AccY/Sensor/Value",
  "Device/SubDeviceList/InertialSensor/AccZ/Sensor/Value",
  "Device/SubDeviceList/InertialSensor/GyrX/Sensor/Value",
  "Device/SubDeviceList/InertialSensor/GyrY/Sensor/Value",
  "Device/SubDeviceList/InertialSensor/GyrRef/Sensor/Value",
  
  // Button[nButton]
  "Device/SubDeviceList/ChestBoard/Button/Sensor/Value",
  
  // Bumper[nBumper]
  "Device/SubDeviceList/LFoot/Bumper/Left/Sensor/Value",
  "Device/SubDeviceList/LFoot/Bumper/Right/Sensor/Value",
  "Device/SubDeviceList/RFoot/Bumper/Left/Sensor/Value",
  "Device/SubDeviceList/RFoot/Bumper/Right/Sensor/Value",

  // Fsr[nFsr]
  "Device/SubDeviceList/LFoot/FSR/FrontLeft/Sensor/Value",
  "Device/SubDeviceList/LFoot/FSR/RearLeft/Sensor/Value",
  "Device/SubDeviceList/LFoot/FSR/FrontRight/Sensor/Value",
  "Device/SubDeviceList/LFoot/FSR/RearRight/Sensor/Value",
  "Device/SubDeviceList/RFoot/FSR/FrontLeft/Sensor/Value",
  "Device/SubDeviceList/RFoot/FSR/RearLeft/Sensor/Value",
  "Device/SubDeviceList/RFoot/FSR/FrontRight/Sensor/Value",
  "Device/SubDeviceList/RFoot/FSR/RearRight/Sensor/Value",

  // Us[nUs]
  "Device/SubDeviceList/US/Left/Sensor/Value",
  "Device/SubDeviceList/US/Left/Sensor/Value1",
  "Device/SubDeviceList/US/Left/Sensor/Value2",
  "Device/SubDeviceList/US/Left/Sensor/Value3",
  "Device/SubDeviceList/US/Right/Sensor/Value",
  "Device/SubDeviceList/US/Right/Sensor/Value1",
  "Device/SubDeviceList/US/Right/Sensor/Value2",
  "Device/SubDeviceList/US/Right/Sensor/Value3",

  // Battery[nBattery]
  "Device/SubDeviceList/Battery/Charge/Sensor/Value",
  "Device/SubDeviceList/Battery/Current/Sensor/Value",
};
static const int nSensorNames = sizeof(sensorNames)/sizeof(const char *);

static const char* actuatorJointNames[] = {
  "Device/SubDeviceList/HeadYaw/Position/Actuator/Value",
  "Device/SubDeviceList/HeadPitch/Position/Actuator/Value",
  "Device/SubDeviceList/LShoulderPitch/Position/Actuator/Value",
  "Device/SubDeviceList/LShoulderRoll/Position/Actuator/Value",
  "Device/SubDeviceList/LElbowYaw/Position/Actuator/Value",
  "Device/SubDeviceList/LElbowRoll/Position/Actuator/Value",
  "Device/SubDeviceList/LHipYawPitch/Position/Actuator/Value",
  "Device/SubDeviceList/LHipRoll/Position/Actuator/Value",
  "Device/SubDeviceList/LHipPitch/Position/Actuator/Value",
  "Device/SubDeviceList/LKneePitch/Position/Actuator/Value",
  "Device/SubDeviceList/LAnklePitch/Position/Actuator/Value",
  "Device/SubDeviceList/LAnkleRoll/Position/Actuator/Value",
  "Device/SubDeviceList/RHipYawPitch/Position/Actuator/Value",
  "Device/SubDeviceList/RHipRoll/Position/Actuator/Value",
  "Device/SubDeviceList/RHipPitch/Position/Actuator/Value",
  "Device/SubDeviceList/RKneePitch/Position/Actuator/Value",
  "Device/SubDeviceList/RAnklePitch/Position/Actuator/Value",
  "Device/SubDeviceList/RAnkleRoll/Position/Actuator/Value",
  "Device/SubDeviceList/RShoulderPitch/Position/Actuator/Value",
  "Device/SubDeviceList/RShoulderRoll/Position/Actuator/Value",
  "Device/SubDeviceList/RElbowYaw/Position/Actuator/Value",
  "Device/SubDeviceList/RElbowRoll/Position/Actuator/Value",

  "Device/SubDeviceList/HeadYaw/Hardness/Actuator/Value",
  "Device/SubDeviceList/HeadPitch/Hardness/Actuator/Value",
  "Device/SubDeviceList/LShoulderPitch/Hardness/Actuator/Value",
  "Device/SubDeviceList/LShoulderRoll/Hardness/Actuator/Value",
  "Device/SubDeviceList/LElbowYaw/Hardness/Actuator/Value",
  "Device/SubDeviceList/LElbowRoll/Hardness/Actuator/Value",
  "Device/SubDeviceList/LHipYawPitch/Hardness/Actuator/Value",
  "Device/SubDeviceList/LHipRoll/Hardness/Actuator/Value",
  "Device/SubDeviceList/LHipPitch/Hardness/Actuator/Value",
  "Device/SubDeviceList/LKneePitch/Hardness/Actuator/Value",
  "Device/SubDeviceList/LAnklePitch/Hardness/Actuator/Value",
  "Device/SubDeviceList/LAnkleRoll/Hardness/Actuator/Value",
  "Device/SubDeviceList/RHipYawPitch/Hardness/Actuator/Value",
  "Device/SubDeviceList/RHipRoll/Hardness/Actuator/Value",
  "Device/SubDeviceList/RHipPitch/Hardness/Actuator/Value",
  "Device/SubDeviceList/RKneePitch/Hardness/Actuator/Value",
  "Device/SubDeviceList/RAnklePitch/Hardness/Actuator/Value",
  "Device/SubDeviceList/RAnkleRoll/Hardness/Actuator/Value",
  "Device/SubDeviceList/RShoulderPitch/Hardness/Actuator/Value",
  "Device/SubDeviceList/RShoulderRoll/Hardness/Actuator/Value",
  "Device/SubDeviceList/RElbowYaw/Hardness/Actuator/Value",
  "Device/SubDeviceList/RElbowRoll/Hardness/Actuator/Value",
};
static const int nActuatorJointNames = sizeof(actuatorJointNames)/sizeof(const char *);

static const char* actuatorUsNames[] = {
  // UltraSound
  "Device/SubDeviceList/US/Actuator/Value",
};
static const int nActuatorUsNames = sizeof(actuatorUsNames)/sizeof(const char *);
  
static const char* actuatorLedNames[] = {
  // ledChest[nLedChest]
  "Device/SubDeviceList/ChestBoard/Led/Red/Actuator/Value",
  "Device/SubDeviceList/ChestBoard/Led/Green/Actuator/Value",
  "Device/SubDeviceList/ChestBoard/Led/Blue/Actuator/Value",
  
  // ledLeftFoot[nLedLeftFoot]
  "Device/SubDeviceList/LFoot/Led/Red/Actuator/Value",
  "Device/SubDeviceList/LFoot/Led/Green/Actuator/Value",
  "Device/SubDeviceList/LFoot/Led/Blue/Actuator/Value",
  
  // ledRightFoot[nLedRightFoot]
  "Device/SubDeviceList/RFoot/Led/Red/Actuator/Value",
  "Device/SubDeviceList/RFoot/Led/Green/Actuator/Value",
  "Device/SubDeviceList/RFoot/Led/Blue/Actuator/Value",

  // ledLeftFace[nLedLeftFace]
  "Device/SubDeviceList/Face/Led/Red/Left/0Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Left/45Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Left/90Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Left/135Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Left/180Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Left/225Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Left/270Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Left/315Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Left/0Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Left/45Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Left/90Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Left/135Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Left/180Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Left/225Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Left/270Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Left/315Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Left/0Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Left/45Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Left/90Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Left/135Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Left/180Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Left/225Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Left/270Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Left/315Deg/Actuator/Value",

  // ledRightFace[nLedRightFace]
  "Device/SubDeviceList/Face/Led/Red/Right/0Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Right/45Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Right/90Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Right/135Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Right/180Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Right/225Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Right/270Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Red/Right/315Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Right/0Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Right/45Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Right/90Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Right/135Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Right/180Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Right/225Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Right/270Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Green/Right/315Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Right/0Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Right/45Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Right/90Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Right/135Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Right/180Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Right/225Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Right/270Deg/Actuator/Value",
  "Device/SubDeviceList/Face/Led/Blue/Right/315Deg/Actuator/Value",

  // ledEarsLeft[nLedEarsLeft]
  "Device/SubDeviceList/Ears/Led/Left/0Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/36Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/72Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/108Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/144Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/180Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/216Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/252Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/288Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/324Deg/Actuator/Value",

  // ledEarsRight[nLedEarsRight]
  "Device/SubDeviceList/Ears/Led/Right/0Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Right/36Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Right/72Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Right/108Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Right/144Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Right/180Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Right/216Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Right/252Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Right/288Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Right/324Deg/Actuator/Value",
};
static const int nActuatorLedNames = sizeof(actuatorLedNames)/sizeof(const char *);

#endif // shmmap_h
