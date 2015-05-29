#ifndef actuator_process_h_DEFINED
#define actuator_process_h_DEFINED

#include <stdlib.h>
#include <alcore/alptr.h>
#include <alcommon/albroker.h>

int actuator_process_init(AL::ALPtr<AL::ALBroker> pBroker);
int actuator_process();
int actuator_process_exit();

static const char* actuatorNamesPosition[] = {
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
  "Device/SubDeviceList/RElbowRoll/Position/Actuator/Value"
};

static const char* actuatorNamesHardness[] = {
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

static const char* actuatorNamesUs[] = {
  "Device/SubDeviceList/US/Actuator/Value",
};

static const char* actuatorNamesLedChest[] = {
  "Device/SubDeviceList/ChestBoard/Led/Red/Actuator/Value",
  "Device/SubDeviceList/ChestBoard/Led/Green/Actuator/Value",
  "Device/SubDeviceList/ChestBoard/Led/Blue/Actuator/Value"
};

static const char* actuatorNamesLedFootLeft[] = {
  "Device/SubDeviceList/LFoot/Led/Red/Actuator/Value",
  "Device/SubDeviceList/LFoot/Led/Green/Actuator/Value",
  "Device/SubDeviceList/LFoot/Led/Blue/Actuator/Value"
};

static const char* actuatorNamesLedFootRight[] = {
  "Device/SubDeviceList/RFoot/Led/Red/Actuator/Value",
  "Device/SubDeviceList/RFoot/Led/Green/Actuator/Value",
  "Device/SubDeviceList/RFoot/Led/Blue/Actuator/Value",
};

static const char* actuatorNamesLedFaceLeft[] = {
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
  "Device/SubDeviceList/Face/Led/Blue/Left/315Deg/Actuator/Value"
};

static const char* actuatorNamesLedFaceRight[] = {
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
  "Device/SubDeviceList/Face/Led/Blue/Right/315Deg/Actuator/Value"
};

static const char* actuatorNamesLedEarsLeft[] = {
  "Device/SubDeviceList/Ears/Led/Left/0Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/36Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/72Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/108Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/144Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/180Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/216Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/252Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/288Deg/Actuator/Value",
  "Device/SubDeviceList/Ears/Led/Left/324Deg/Actuator/Value"
};

static const char* actuatorNamesLedEarsRight[] = {
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

static const int nJoint = sizeof(actuatorNamesPosition)/sizeof(char *);

static struct structActuatorKeys {
  const char *key;
  unsigned int size;
  const char **names;
} actuatorKeys[] = {
  {"time", 1, NULL},
  {"count", 1, NULL},
  {"disable", 1, NULL},
  {"position", nJoint, actuatorNamesPosition},
  {"hardness", nJoint, actuatorNamesHardness},
  {"command", nJoint, NULL},
  {"velocity", nJoint, NULL},
  {"us", sizeof(actuatorNamesUs)/sizeof(char *), actuatorNamesUs},
  {"ledChest", sizeof(actuatorNamesLedChest)/sizeof(char *),
   actuatorNamesLedChest},
  {"ledFootLeft", sizeof(actuatorNamesLedFootLeft)/sizeof(char *),
   actuatorNamesLedFootLeft},
  {"ledFootRight", sizeof(actuatorNamesLedFootRight)/sizeof(char *),
   actuatorNamesLedFootRight},
  {"ledFaceLeft", sizeof(actuatorNamesLedFaceLeft)/sizeof(char *),
   actuatorNamesLedFaceLeft},
  {"ledFaceRight", sizeof(actuatorNamesLedFaceRight)/sizeof(char *),
   actuatorNamesLedFaceRight},
  {"ledEarsLeft", sizeof(actuatorNamesLedEarsLeft)/sizeof(char *),
   actuatorNamesLedEarsLeft},
  {"ledEarsRight", sizeof(actuatorNamesLedEarsRight)/sizeof(char *),
   actuatorNamesLedEarsRight},
  {NULL, 0, NULL}
};

#endif
