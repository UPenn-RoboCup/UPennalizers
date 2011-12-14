#ifndef HuboKinematics_h_DEFINED
#define HuboKinematics_h_DEFINED

#include <math.h>
#include <vector>
#include "Transform.h"

enum {LEG_LEFT = 0, LEG_RIGHT = 1};

//const double PI = 3.14159265358979323846;
const double PI = 2*asin(1);
const double SQRT2 = sqrt(2);


const double neckOffsetZ = .08; //Hubo
const double neckOffsetX = -.109;//Hubo
const double shoulderOffsetX = .013;//OP, calculated from spec
const double shoulderOffsetY = .335; //op, spec 
const double shoulderOffsetZ = .029; //Hubo
const double handOffsetX = .058;
const double handOffsetZ = .0159;
const double upperArmLength = .060;  //OP, spec
const double lowerArmLength = .129;  //OP, spec

//Hubo values (guesswork from webots prototype file)
//const double hipOffsetY = .089;    //Hubo
const double hipOffsetY = .0741;    //Hubo
const double hipOffsetZ = .1345;   //Hubo
const double hipOffsetX = .00;     //Hubo
//const double thighLength = .31;    //Hubo
//const double tibiaLength = .305;   //Hubo
const double thighLength = .30;    //Hubo
const double tibiaLength = .30;   //Hubo
//const double footHeight = .091;    //Hubo
const double footHeight = .083;    //Hubo
const double kneeOffsetX = .0;     //Hubo

const double dThigh = sqrt(thighLength*thighLength+kneeOffsetX*kneeOffsetX);
const double aThigh = atan(kneeOffsetX/thighLength);
const double dTibia = sqrt(tibiaLength*tibiaLength+kneeOffsetX*kneeOffsetX);
const double aTibia = atan(kneeOffsetX/tibiaLength);

Transform darwinop_kinematics_forward_head(const double *q);
Transform darwinop_kinematics_forward_larm(const double *q);
Transform darwinop_kinematics_forward_rarm(const double *q);
Transform darwinop_kinematics_forward_lleg(const double *q);
Transform darwinop_kinematics_forward_rleg(const double *q);

std::vector<double>
darwinop_kinematics_inverse_leg(
			   const Transform trLeg,
			   const int leg,
			   double unused=0);

std::vector<double>
darwinop_kinematics_inverse_lleg(const Transform trLeg, double unused=0);

std::vector<double>
darwinop_kinematics_inverse_rleg(const Transform trLeg, double unused=0);

std::vector<double>
darwinop_kinematics_inverse_legs(
			    const double *pLLeg,
			    const double *pRLeg,
			    const double *pTorso,
			    int legSupport=0);

#endif
