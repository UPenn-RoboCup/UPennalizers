#ifndef naoKinematics_h_DEFINED
#define naoKinematics_h_DEFINED

#include <math.h>
#include <vector>
#include "Transform.h"

enum {LEG_LEFT = 0, LEG_RIGHT = 1};

//const double PI = 3.14159265358979323846;
const double PI = 2*asin(1);
const double SQRT2 = sqrt(2);

const double neckOffsetZ = .1265;

const double shoulderOffsetY = .098;
const double shoulderOffsetZ = .100;
const double handOffsetX = .058;
const double handOffsetZ = .0159;
const double upperArmLength = .090;
const double lowerArmLength = .05055;

const double hipOffsetY = .050;
const double hipOffsetZ = .085;
const double thighLength = .100;
const double tibiaLength = .10274;
const double footHeight = .04511;

Transform nao_kinematics_forward_head(const double *q);
Transform nao_kinematics_forward_larm(const double *q);
Transform nao_kinematics_forward_rarm(const double *q);
Transform nao_kinematics_forward_lleg(const double *q);
Transform nao_kinematics_forward_rleg(const double *q);

std::vector<double>
nao_kinematics_inverse_leg(
			   const Transform trLeg,
			   const int leg,
			   const double hipYawPitch = 1);

std::vector<double>
nao_kinematics_inverse_lleg(
			   const Transform trLeg,
			   const double hipYawPitch = 1);

std::vector<double>
nao_kinematics_inverse_rleg(
			   const Transform trLeg,
			   const double hipYawPitch = 1);

std::vector<double>
nao_kinematics_inverse_legs(
			    const double *pLLeg,
			    const double *pRLeg,
			    const double *pTorso,
			    const int legSupport);

#endif

