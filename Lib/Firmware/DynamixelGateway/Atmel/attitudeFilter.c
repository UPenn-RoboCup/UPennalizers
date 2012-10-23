#include "config.h"
#include "attitudeFilter.h"
#include <math.h>

//latest rotation matrix
volatile float R[9] = {1,0,0, 0,1,0, 0,0,1};

//the delta rotation matrix
volatile float dR[9] = {1,0,0, 0,1,0, 0,0,1};

//actual accelerations and angular rates
volatile float ax,ay,az,wx,wy,wz;

uint16_t imuUpdateCntr = 0;
uint8_t gyrosCalibrated = 0;

//acceleration biases
float axb = BIAS_ACC_X;
float ayb = BIAS_ACC_Y;
float azb = BIAS_ACC_Z;

//rate gyro biases (to be calibrated at start up)
float wxb = 0;
float wyb = 0;
float wzb = 0;

//error in biases (experimental)
float wxdb = 0;
float wydb = 0;
float wzdb = 0;


//sensitivities for converting raw values into real units
float axs = SENS_ACC_X; //ADC_VOLTAGE_MV/1023.0 * SENS_ACC_X;
float ays = SENS_ACC_Y; //ADC_VOLTAGE_MV/1023.0 * SENS_ACC_Y;
float azs = SENS_ACC_Z; //ADC_VOLTAGE_MV/1023.0 * SENS_ACC_Z;
float wxs = ADC_VOLTAGE_MV/1023.0 * SENS_GYRO_X;
float wys = ADC_VOLTAGE_MV/1023.0 * SENS_GYRO_Y;
float wzs = ADC_VOLTAGE_MV/1023.0 * SENS_GYRO_Z;

const float dt=64.0*ADC_TIMER_PERIOD_TICS/F_CPU; //IMU_SAMPLE_RATE;

//factors for combining rate gyro and accelerometer info (malfa=1-alpha)
float alpha=0.005;
float malpha = 0.995;


float groll,gpitch,gyaw,aroll,apitch,nroll,npitch,nyaw,myaw;
float sinx,siny,sinz,cosx,cosy,cosz;
float wxt,wyt,wzt;


void ResetR()
{
  R[0] = 1; R[1] = 0; R[2] = 0; R[3] = 0;
  R[4] = 1; R[5] = 0; R[6] = 0; R[7] = 0;
  R[8] = 1;
}

void ResetdR()
{
  dR[0] = 1; dR[1] = 0; dR[2] = 0; dR[3] = 0;
  dR[4] = 1; dR[5] = 0; dR[6] = 0; dR[7] = 0;
  dR[8] = 1;
}

void ResetImu()
{
  ResetR();
  ResetdR();
  
  imuUpdateCntr=0;
  gyrosCalibrated=0;
}



//calculate the required components of the new rotation matrix
//so that rpy (roll,pitch,yaw) can be extracted
//dR is the delta rotation, assuming small angle rotations are done
//one after the other instead of exponentiation
//The matrix multiplication is R*dR
int CalcGyroRPY()
{
  float RR21 = R[2]*dR[3] + R[5]       + R[8]*dR[5];
  float RR22 = R[2]*dR[6] + R[5]*dR[7] + R[8]      ;
  float RR20 = R[2]       + R[5]*dR[1] + R[8]*dR[2];
  float RR10 = R[1]       + R[4]*dR[1] + R[7]*dR[2]; 
  float RR00 = R[0]       + R[3]*dR[1] + R[6]*dR[2];

  //extract the values after rate gyro update
  groll  = atan2(RR21,RR22);
  gpitch = atan2(-RR20,sqrt(RR21*RR21 + RR22*RR22));
  gyaw   = atan2(RR10,RR00);
  
  //zero out the delta matrix, since the values in dR can be accumulated
  //over several data collections
  ResetdR();
  
  return 0;
}

int ProcessImuReadings(uint16_t * adcVals, float * rpy)
{
  imuUpdateCntr++;
  
  //initialization of rate gyros
  if (!gyrosCalibrated)
  {
    //accumulate values
    if (imuUpdateCntr <= NUM_GYRO_CALIB_SAMPLES)
    {
      wxb+= (int16_t)adcVals[ADC_WX_IND];
      wyb+= (int16_t)adcVals[ADC_WY_IND];
      wzb+= (int16_t)adcVals[ADC_WZ_IND];
    }
    
    
    //calculate average
    if (imuUpdateCntr == NUM_GYRO_CALIB_SAMPLES)
    {
      wxb /= NUM_GYRO_CALIB_SAMPLES;
      wyb /= NUM_GYRO_CALIB_SAMPLES;
      wzb /= NUM_GYRO_CALIB_SAMPLES;
      gyrosCalibrated = 1;
    }
    else
    {
      return 0;
    }
  }
  
  //calculate floating point values
  ax =  ((float)adcVals[ADC_AX_IND] - axb) * axs;
  ay =  ((float)adcVals[ADC_AY_IND] - ayb) * ays;
  az =  ((float)adcVals[ADC_AZ_IND] - azb) * azs;
  wx =  -((float)adcVals[ADC_WX_IND] - wxb) * wxs;
  wy =  ((float)adcVals[ADC_WY_IND] - wyb) * wys;
  wz =  ((float)adcVals[ADC_WZ_IND] - wzb) * wzs;
  
  
  wxt = (wx+wxdb)*dt;
  wyt = (wy+wydb)*dt;
  wzt = (wz+wzdb)*dt;
  
  
  //stuff the delta matrix. This is derived from linearized equation
  //dR = dRz * dRy * dRx, with sinx = x and cosx = 1, since dt is small
  //only part of the dR matrix is calculated, since we don't need all 
  //components in the CalcGyroRPY function
  dR[1] += wzt;
  dR[2] += -wyt;
  dR[3] += -wzt;
  dR[5] += wxt;
  dR[6] += wyt;
  dR[7] += -wxt;
  
  
  //skip processing every other time
  if (imuUpdateCntr % 1)
    return 0;
  
  //calculate the gyro update
  CalcGyroRPY();
  
  
  //calculate the roll and pitch based on the current accelerometer values
  apitch  = -atan2(ax,sqrt(ay*ay + az*az));
  aroll   =  atan2(ay,az);

  //combine the rate gyro prediction with accelerometer prediction
  nroll   = alpha*aroll  + malpha*groll;
  npitch  = alpha*apitch + malpha*gpitch;
  nyaw    = gyaw; //no accelerometer prediction for yaw
  
  sinx    = sin(nroll);
  siny    = sin(npitch);
  cosx    = cos(nroll);
  cosy    = cos(npitch);
  
  //calculate the components of the rotation matrix for the next iteration
  sinz = sin(nyaw);
  cosz = cos(nyaw);
  
  float sinysinx = siny*sinx;
  float sinycosx = siny*cosx;
  R[0] = cosz*cosy;
  R[1] = sinz*cosy;
  R[2] = -siny;
  R[3] = cosz*sinysinx - sinz*cosx;
  R[4] = sinz*sinysinx + cosz*cosx;
  R[5] = cosy*sinx;
  R[6] = cosz*sinycosx + sinz*sinx;
  R[7] = sinz*sinycosx - cosz*sinx;
  R[8] = cosy*cosx;
  
  rpy[1] = -nroll;
  rpy[0] = npitch;
  rpy[2] = nyaw;
  
  return 0;
}
