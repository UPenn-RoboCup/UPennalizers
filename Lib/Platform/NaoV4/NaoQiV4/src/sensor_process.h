#ifndef sensor_process_h_DEFINED
#define sensor_process_h_DEFINED

#include <stdlib.h>
#include <alcore/alptr.h>
#include <alcommon/albroker.h>

int sensor_process_init(AL::ALPtr<AL::ALBroker> pBroker);
int sensor_process();
int sensor_process_exit();

static const char* sensorNamesPosition[] = {
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
};
  
static const char* sensorNamesCurrent[] = {
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
};

static const char* sensorNamesTemperature[] = {
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
};

static const char* sensorNamesImuAngle[] = {
  "Device/SubDeviceList/InertialSensor/AngleX/Sensor/Value",
  "Device/SubDeviceList/InertialSensor/AngleY/Sensor/Value",
};
static const char* sensorNamesImuAcc[] = {
  "Device/SubDeviceList/InertialSensor/AccX/Sensor/Value",
  "Device/SubDeviceList/InertialSensor/AccY/Sensor/Value",
  "Device/SubDeviceList/InertialSensor/AccZ/Sensor/Value",
};
static const char* sensorNamesImuGyr[] = {
  "Device/SubDeviceList/InertialSensor/GyrX/Sensor/Value",
  "Device/SubDeviceList/InertialSensor/GyrY/Sensor/Value",
  "Device/SubDeviceList/InertialSensor/GyrRef/Sensor/Value",
};

static const char* sensorNamesButton[] = {
  "Device/SubDeviceList/ChestBoard/Button/Sensor/Value",
};  

static const char* sensorNamesBumperLeft[] = {
  "Device/SubDeviceList/LFoot/Bumper/Left/Sensor/Value",
  "Device/SubDeviceList/LFoot/Bumper/Right/Sensor/Value",
};
static const char* sensorNamesBumperRight[] = {
  "Device/SubDeviceList/RFoot/Bumper/Left/Sensor/Value",
  "Device/SubDeviceList/RFoot/Bumper/Right/Sensor/Value",
};

static const char* sensorNamesFsrLeft[] = {
  "Device/SubDeviceList/LFoot/FSR/FrontLeft/Sensor/Value",
  "Device/SubDeviceList/LFoot/FSR/RearLeft/Sensor/Value",
  "Device/SubDeviceList/LFoot/FSR/FrontRight/Sensor/Value",
  "Device/SubDeviceList/LFoot/FSR/RearRight/Sensor/Value",
};
static const char* sensorNamesFsrRight[] = {
  "Device/SubDeviceList/RFoot/FSR/FrontLeft/Sensor/Value",
  "Device/SubDeviceList/RFoot/FSR/RearLeft/Sensor/Value",
  "Device/SubDeviceList/RFoot/FSR/FrontRight/Sensor/Value",
  "Device/SubDeviceList/RFoot/FSR/RearRight/Sensor/Value",
};

static const char* sensorNamesUsLeft[] = {
  "Device/SubDeviceList/US/Left/Sensor/Value",
  "Device/SubDeviceList/US/Left/Sensor/Value1",
  "Device/SubDeviceList/US/Left/Sensor/Value2",
  "Device/SubDeviceList/US/Left/Sensor/Value3",
  "Device/SubDeviceList/US/Left/Sensor/Value4",
  "Device/SubDeviceList/US/Left/Sensor/Value5",
  "Device/SubDeviceList/US/Left/Sensor/Value6",
  "Device/SubDeviceList/US/Left/Sensor/Value7",
  "Device/SubDeviceList/US/Left/Sensor/Value8",
  "Device/SubDeviceList/US/Left/Sensor/Value9",
};
static const char* sensorNamesUsRight[] = {
  "Device/SubDeviceList/US/Right/Sensor/Value",
  "Device/SubDeviceList/US/Right/Sensor/Value1",
  "Device/SubDeviceList/US/Right/Sensor/Value2",
  "Device/SubDeviceList/US/Right/Sensor/Value3",
  "Device/SubDeviceList/US/Right/Sensor/Value4",
  "Device/SubDeviceList/US/Right/Sensor/Value5",
  "Device/SubDeviceList/US/Right/Sensor/Value6",
  "Device/SubDeviceList/US/Right/Sensor/Value7",
  "Device/SubDeviceList/US/Right/Sensor/Value8",
  "Device/SubDeviceList/US/Right/Sensor/Value9",
};
static const char* sensorNamesUsCommand[] = {
  "Device/SubDeviceList/US/Actuator/Value",
};

static const char* sensorNamesBatteryCharge[] = {
  "Device/SubDeviceList/Battery/Charge/Sensor/Value",
};
static const char* sensorNamesBatteryCurrent[] = {
  "Device/SubDeviceList/Battery/Current/Sensor/Value",
};

static const char* sensorNamesCommand[] = {
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
};

static const char* sensorNamesHardness[] = {
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

static struct structSensorKeys {
  const char *key;
  unsigned int size;
  const char **names;
} sensorKeys[] = {
  {"time", 1, NULL},
  {"count", 1, NULL},
  {"position", sizeof(sensorNamesPosition)/sizeof(char *), sensorNamesPosition},
  {"command", sizeof(sensorNamesCommand)/sizeof(char *), sensorNamesCommand},

  {"imuAngle", sizeof(sensorNamesImuAngle)/sizeof(char *), sensorNamesImuAngle},
  {"imuAcc", sizeof(sensorNamesImuAcc)/sizeof(char *), sensorNamesImuAcc},
  {"imuGyr", sizeof(sensorNamesImuGyr)/sizeof(char *), sensorNamesImuGyr},

  {"hardness", sizeof(sensorNamesHardness)/sizeof(char *), sensorNamesHardness},
  {"current", sizeof(sensorNamesCurrent)/sizeof(char *), sensorNamesCurrent},
  {"temperature", sizeof(sensorNamesTemperature)/sizeof(char *), sensorNamesTemperature},
  {"button", sizeof(sensorNamesButton)/sizeof(char *), sensorNamesButton},
  {"bumperLeft", sizeof(sensorNamesBumperLeft)/sizeof(char *),
   sensorNamesBumperLeft},
  {"bumperRight", sizeof(sensorNamesBumperRight)/sizeof(char *),
   sensorNamesBumperRight},
  {"fsrLeft", sizeof(sensorNamesFsrLeft)/sizeof(char *), sensorNamesFsrLeft},
  {"fsrRight", sizeof(sensorNamesFsrRight)/sizeof(char *), sensorNamesFsrRight},
  {"usLeft", sizeof(sensorNamesUsLeft)/sizeof(char *), sensorNamesUsLeft},
  {"usRight", sizeof(sensorNamesUsRight)/sizeof(char *), sensorNamesUsRight},
  {"usCommand", sizeof(sensorNamesUsCommand)/sizeof(char *), sensorNamesUsCommand},
  {"batteryCharge", sizeof(sensorNamesBatteryCharge)/sizeof(char *),
   sensorNamesBatteryCharge},
  {"batteryCurrent", sizeof(sensorNamesBatteryCurrent)/sizeof(char *),
   sensorNamesBatteryCurrent},
  {NULL, 0, NULL}
};

#endif
