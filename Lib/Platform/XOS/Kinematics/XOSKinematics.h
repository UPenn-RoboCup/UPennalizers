#ifndef darwinKinematics_h_DEFINED
#define darwinKinematics_h_DEFINED

#include <math.h>
#include <vector>
#include "Transform.h"

enum {LEG_LEFT = 0, LEG_RIGHT = 1};

//const double PI = 3.14159265358979323846;
const double PI = 2*asin(1);
const double SQRT2 = sqrt(2);

//minihubo values
/*
//origin: waist joint

const double neckOffsetZ = .100+.30; //
const double neckOffsetX =  .014;
const double shoulderOffsetY = .857;
const double shoulderOffsetZ = .86;
const double upperArmLength = .108 ;
const double lowerArmLength = .100 ;

const double hipOffsetY = .0379;
const double hipOffsetZ = .08225;
const double thighLength = .0905;
const double tibiaLength = .0905;
const double kneeOffsetRad=.2343; //Hubo has knee offset
const double footHeight = .032;
*/


//DARWIN IV VALUES
//ORIGIN: WAIST JOINT
/*
const double neckOffsetZ = .102;
const double shoulderOffsetY = .117;
const double shoulderOffsetZ = .83;
const double handOffsetX = .0;
const double handOffsetZ = .0;
const double upperArmLength = .110;
const double lowerArmLength = .149;

const double hipOffsetY = .0405;
const double hipOffsetZ = .104;
const double thighLength = .115;
const double tibiaLength = .115;
const double rKneeOffset1 = 0; //knee offset angle
const double rKneeOffset2 = 0; //knee offset angle
const double footHeight = .035;
*/

//DARWIN XOS, Rev 2 VALUES
//ORIGIN: WAIST JOINT
//Modified from Darwin IV with leg length adjustments
const double neckOffsetZ = .102;
const double shoulderOffsetY = .117;
const double shoulderOffsetZ = .83;
const double handOffsetX = .0;
const double handOffsetZ = .0;
const double upperArmLength = .110;
const double lowerArmLength = .149;

const double hipOffsetY = .0405;
const double hipOffsetZ = .104;
const double thighLength = .195;
const double tibiaLength = .15;
const double rKneeOffset1 = 0; //knee offset angle
const double rKneeOffset2 = 0; //knee offset angle
const double footHeight = .038;

//DARWIN LC VALUES
//origin: middle of hip joints
/*
const double camOffsetX=.0436;
const double camOffsetZ=.0310;
const double neckOffsetZ = ; //hip joint to neck: 174.5mm
const double neckOffsetX = .010;
const double shoulderOffsetX = .010;
const double shoulderOffsetY = .0710;
const double shoulderOffsetZ = ; //hip joint to shoulder: 123.5mm
const double shoulderJointOffsetZ = -.0270; //darwin LC has shoulder joint offset
const double upperArmLength = .0580;
const double lowerArmLength = .1145;
const double hipOffsetY = .0370;
const double hipOffsetZ = 0;
const double thighLength = .0764;
const double tibiaLength = .0764; 
const double kneeOffsetX = 0.020;
const double rKneeOffset1 = asin(kneeOffsetX/thighLength); //LC has knee offsetknee offset angle
const double rKneeOffset2 = asin(kneeOffsetX/tibiaLength); //LC has knee offsetknee offset angle

const double footHeight = .032;
*/
 
 
Transform darwin_kinematics_forward_head(const double *q);
Transform darwin_kinematics_forward_larm(const double *q);
Transform darwin_kinematics_forward_rarm(const double *q);
Transform darwin_kinematics_forward_lleg(const double *q);
Transform darwin_kinematics_forward_rleg(const double *q);

std::vector<double>
darwin_kinematics_inverse_leg(
			   const Transform trLeg,
			   const int leg,
			   const double hipYawPitch = 1);

std::vector<double>
darwin_kinematics_inverse_lleg(
			   const Transform trLeg,
			   const double hipYawPitch = 1);

std::vector<double>
darwin_kinematics_inverse_rleg(
			   const Transform trLeg,
			   const double hipYawPitch = 1);

std::vector<double>
darwin_kinematics_inverse_legs(
			    const double *pLLeg,
			    const double *pRLeg,
			    const double *pTorso,
			    const int legSupport);

#endif

