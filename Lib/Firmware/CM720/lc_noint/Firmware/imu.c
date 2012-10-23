#include <stdint.h>
#include <math.h>

// Rotation matrix
volatile float R[3][3] =
  {{1,0,0},{0,1,0},{0,0,1}};

float accOffset[3] = {337, 337, 337}; // ~1.5 V
float accScale[3] = {1/6.8, 1/6.8, 1/6.8}; // m/s^2
float gyrOffset[3] = {252, 252, 252}; // 1.23 V

//float gyrScale[3] = {1/39.1, 1/39.1, 1/39.1}; // rad/s
//float gyrScale[3] = {1/(2*39.1), 1/(2*39.1), 1/(2*39.1)}; // rad/s 
float gyrScale[3] = {1/(4*39.1), 1/(4*39.1), 1/(4*39.1)}; // rad/s 

float accMagnitudeMin = 8.0;
float accMagnitudeMax = 12.0;
float accFilterTime = 1.0;

float acc[3], gyr[3];
float angle[3];

#define NGYR 2

float* imu_get_angle() {
  return angle;
}

int imu_filter_gyr(uint16_t *gyrRaw, float dt) {
  int i;

  for (i = 0; i < NGYR; i++) {
    gyr[i] = gyrScale[i]*(gyrRaw[i]-gyrOffset[i]);
  }

  // Quick and Dirty small angle calculations:
  angle[0] += cos(angle[1])*gyr[0]*dt;
  angle[1] += cos(angle[0])*gyr[1]*dt;

  return 0;
}

int imu_filter_acc(uint16_t *accRaw, float dt) {
  int i;
  float accMagnitude=0;
  float aX, aY;

  for (i = 0; i < 3; i++) {
    acc[i] = accScale[i]*(accRaw[i]-accOffset[i]);
    accMagnitude += acc[i]*acc[i];
  }
  accMagnitude = sqrt(accMagnitude);

  if ((accMagnitude < accMagnitudeMin) ||
      (accMagnitude > accMagnitudeMax)) 
    return -1;

  aX = asin(acc[0]/accMagnitude);
  aY = asin(acc[1]/accMagnitude);

  // Filter angles:
  angle[0] += (dt/accFilterTime)*(aX-angle[0]);
  angle[1] += (dt/accFilterTime)*(aY-angle[1]);

  return 0;
}
