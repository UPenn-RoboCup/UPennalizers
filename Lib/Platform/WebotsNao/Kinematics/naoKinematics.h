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
const double kneeOffsetX = 0.00;

    
//Nao foot size: 0.148
//TODO: correct ankle offset
const double footToeX = 0.100;
const double footHeelX = 0.048; 

const double dThigh = sqrt(thighLength*thighLength+kneeOffsetX*kneeOffsetX);
const double aThigh = atan(kneeOffsetX/thighLength);
const double dTibia = sqrt(tibiaLength*tibiaLength+kneeOffsetX*kneeOffsetX);
const double aTibia = atan(kneeOffsetX/tibiaLength);



const double llegLink0[3] = {0,hipOffsetY,-hipOffsetZ};
const double rlegLink0[3] = {0,-hipOffsetY,-hipOffsetZ};

const double legLink[7][3]={
	{0,hipOffsetY,-hipOffsetZ}, //waist-hipyaw
	{0,0,0}, //hip yaw-roll
	{0,0,0}, //hip roll-pitch
	{-kneeOffsetX,0,-thighLength}, //hip pitch-knee
	{kneeOffsetX,0,-tibiaLength}, //knee-ankle pitch
	{0,0,0}, //ankle pitch-ankle roll
	{0,0,-footHeight}, //ankle roll - foot bottom
};

//torso neck head
const double MassBody[3] = {1.04956, 0.06442,0.60533};
const double bodyCom[3][3]={
	{-0.00413, 0.00009, 0.04342}, //from waist center?
	{-0.00001, 0.00014, -0.02742}, //from neck joint
	{-0.00112, 0.00003, 0.05258} //from jeck joint
};

const double MassArm[5] = {
  //shoulder    //uarm       //elbowyaw //elbowroll
	0.07504, 0.15794,  0.06483,  0.07778,  0
};


//for some reason, nao leg is asymmetric but we just use symmetric data for now
const double MassLeg[6]={
	0.06981, //hipyawpitch
	0.13053, //hipRoll
	0.38968, //hippitch, upper leg
  0.29142, //kneepitch, lower leg
  0.13416, //anklepitch
  0.16184 //foot
};

const double legComL[6][3]={
	{-0.00781,-0.01114,0.02661}, //from hip joint
	{-0.01549,0.00029,-0.00515}, //from hip joint	
	{0.00138,-0.00221,-0.05373}, //from hip joint	
	{0.00453, -0.00225, -0.04936}, //from knee joint
	{0.00045,0.00029,0.00685}, //from ankle joint
	{0.02542,0.00330,-0.03239} //from ankle joint
};

const double legComR[6][3]={
	{-0.00781,0.01114,0.02661}, //from hip joint
	{-0.01549,-0.00029,-0.00515}, //from hip joint	
	{0.00138,0.00221,-0.05373}, //from hip joint	
	{0.00453, 0.00225, -0.04936}, //from knee joint
	{0.00045,-0.00029,0.00685}, //from ankle joint
	{0.02542,-0.00330,-0.03239} //from ankle joint
};









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

std::vector<double> 
nao_kinematics_inverse_leg_heellift(Transform trLeg, int leg, double anklePitchCurrent,double heelliftMin);

std::vector<double> 
nao_kinematics_inverse_leg_toelift(Transform trLeg, int leg, double anklePitchCurrent,double heelliftMin);


std::vector<double>
nao_kinematics_calculate_com_positions(
    const double *qLArm,const double *qRArm,
    const double *qLLeg,const double *qRLeg,const double *qHead);

//for testing
std::vector<double>
nao_kinematics_calculate_com_positions(const double *qLLeg,const double *qRLeg);


#endif

