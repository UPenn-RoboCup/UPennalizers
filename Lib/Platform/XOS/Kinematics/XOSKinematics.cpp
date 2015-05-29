#include "XOSKinematics.h"
#include "Transform.h"
#include <math.h>
#include <stdio.h>

void printTransform(Transform tr) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      printf("%.4g ",tr(i,j));
    }
    printf("\n");
  }
  printf("\n");
}

Transform
darwin_kinematics_forward_head(const double *q)
{
  Transform t;
  t = t.translateZ(neckOffsetZ)
    .mDH(0, 0, q[0], 0)
    .mDH(-PI/2, 0, -PI/2+q[1], 0)
    .rotateX(PI/2).rotateY(PI/2);
  return t;
}

Transform
darwin_kinematics_forward_larm(const double *q)
{
  Transform t;
  t = t.translateY(shoulderOffsetY).translateZ(shoulderOffsetZ)
    .mDH(-PI/2, 0, q[0], 0)
    .mDH(PI/2, 0, PI/2+q[1], 0)
    .mDH(PI/2, 0, q[2], upperArmLength)
    .mDH(-PI/2, 0, q[3], 0)
    .mDH(PI/2, 0, 0, lowerArmLength)
    .rotateX(-PI/2).rotateZ(-PI/2)
    .translateX(handOffsetX).translateZ(-handOffsetZ);
  return t;
}

Transform
darwin_kinematics_forward_rarm(const double *q)
{
  Transform t;
  t = t.translateY(-shoulderOffsetY).translateZ(shoulderOffsetZ)
    .mDH(-PI/2, 0, q[0], 0)
    .mDH(PI/2, 0, PI/2+q[1], 0)
    .mDH(PI/2, 0, q[2], upperArmLength)
    .mDH(-PI/2, 0, q[3], 0)
    .mDH(PI/2, 0, 0, lowerArmLength)
    .rotateX(-PI/2).rotateZ(-PI/2)
    .translateX(handOffsetX).translateZ(-handOffsetZ);
  return t;
}

Transform
darwin_kinematics_forward_lleg(const double *q)
{
  Transform t;
  t = t.translateY(hipOffsetY).translateZ(-hipOffsetZ)
//  .mDH(-3*PI/4, 0, -PI/2+q[0], 0)
//  .mDH(-PI/2, 0, PI/4+q[1], 0)
// .mDH(PI/2, 0, q[2], 0)
    .mDH(    0, 0, q[0], 0)
    .mDH(-PI/2+q[1], 0, 0, 0)
    .mDH(0, 0, q[2]-PI/2, 0)
    .mDH(0, -thighLength, q[3], 0)
    .mDH(0, -tibiaLength, q[4], 0)
    .mDH(-PI/2, 0, q[5], 0)
    .rotateZ(PI).rotateY(-PI/2).translateZ(-footHeight);
  return t;
}

Transform
darwin_kinematics_forward_rleg(const double *q)
{
  Transform t;
  t = t.translateY(-hipOffsetY).translateZ(-hipOffsetZ)
//  .mDH(-PI/4, 0, -PI/2+q[0], 0)
//  .mDH(-PI/2, 0, -PI/4+q[1], 0)
//  .mDH(PI/2, 0, q[2], 0)
    .mDH(    0, 0, q[0], 0)
    .mDH(-PI/2+q[1], 0, 0, 0)
    .mDH(0, 0, q[2]-PI/2, 0)
    .mDH(0, -thighLength, q[3], 0)
    .mDH(0, -tibiaLength, q[4], 0)
    .mDH(-PI/2, 0, q[5], 0)
    .rotateZ(PI).rotateY(-PI/2).translateZ(-footHeight);
  return t;
}
std::vector<double>
darwin_kinematics_inverse_leg(
			   Transform trLeg,
			   int leg, double unused)
{
  std::vector<double> qLeg(6);
  bool left = (leg == LEG_LEFT); // Left leg

  Transform trInvLeg = inv(trLeg);
  //  printTransform(trInvLeg);
  //  printTransform(trLeg);

  // Hip Offset vector in Torso frame
  double xHipOffset[3];
  if (left) {
    xHipOffset[0] = 0;
    xHipOffset[1] = hipOffsetY;
    xHipOffset[2] = -hipOffsetZ;
  }
  else {
    xHipOffset[0] = 0;
    xHipOffset[1] = -hipOffsetY;
    xHipOffset[2] = -hipOffsetZ;
  }

  // Hip Offset in Leg frame
  double xLeg[3];
  for (int i = 0; i < 3; i++)
    xLeg[i] = xHipOffset[i];
  trInvLeg.apply(xLeg);
  xLeg[2] -= footHeight;

  // Knee pitch
  double dLeg = xLeg[0]*xLeg[0] + xLeg[1]*xLeg[1] + xLeg[2]*xLeg[2];
  double cKnee = .5*(dLeg -tibiaLength*tibiaLength -thighLength*thighLength)/
    (tibiaLength*thighLength);
    
  if (cKnee > 1) cKnee = 1;
  if (cKnee < -1) cKnee = -1;
  double kneePitch = acos(cKnee);

  // Angle pitch and roll
  double ankleRoll = atan2(xLeg[1], xLeg[2]);
  double lLeg = sqrt(dLeg);
  if (lLeg < 1e-16) lLeg = 1e-16;
  double pitch0 = asin(thighLength*sin(kneePitch)/lLeg);
  double anklePitch = asin(-xLeg[0]/lLeg) - pitch0;

  Transform rHipT = trLeg;
  rHipT = rHipT.rotateX(-ankleRoll).rotateY(-anklePitch-kneePitch);

  double hipYaw = atan2(-rHipT(0,1), rHipT(1,1));
  double hipRoll = asin(rHipT(2,1));
  double hipPitch = atan2(-rHipT(2,0), rHipT(2,2));

  /*
  double xAnkle[3];
  xAnkle[0] = 0;
  xAnkle[1] = 0;
  xAnkle[2] = footHeight;
  trLeg.apply(xAnkle);
  for (int i = 0; i < 3; i++) {
    xAnkle[i] -= xHipOffset[i];
  }

  rHipT.clear();
  rHipT.rotateZ(-hipYaw).apply(xAnkle);

  double hipRoll = atan2(xAnkle[1], -xAnkle[2]);
  double pitch1 = asin(tibiaLength*sin(kneePitch)/lLeg);
  double hipPitch = asin(-xAnkle[0]/lLeg) - pitch1;
  */
  
  qLeg[0] = hipYaw;
  qLeg[1] = hipRoll;
  qLeg[2] = hipPitch-rKneeOffset1;
  qLeg[3] = kneePitch+rKneeOffset1+rKneeOffset2;
  qLeg[4] = anklePitch-rKneeOffset2;
  qLeg[5] = ankleRoll;
  return qLeg;
}

std::vector<double>
darwin_kinematics_inverse_lleg(Transform trLeg, double unused)
{
  return darwin_kinematics_inverse_leg(trLeg, LEG_LEFT, unused);
}

std::vector<double>
darwin_kinematics_inverse_rleg(Transform trLeg, double unused)
{
  return darwin_kinematics_inverse_leg(trLeg, LEG_RIGHT, unused);
}

std::vector<double>
darwin_kinematics_inverse_legs(
			    const double *pLLeg,
			    const double *pRLeg,
			    const double *pTorso,
			    int legSupport)
{
  std::vector<double> qLLeg(12), qRLeg;
  Transform trLLeg = transform6D(pLLeg);
  Transform trRLeg = transform6D(pRLeg);
  Transform trTorso = transform6D(pTorso);

  Transform trTorso_LLeg = inv(trTorso)*trLLeg;
  Transform trTorso_RLeg = inv(trTorso)*trRLeg;

  qLLeg = darwin_kinematics_inverse_lleg(trTorso_LLeg, 0);
  qRLeg = darwin_kinematics_inverse_rleg(trTorso_RLeg, 0);

  qLLeg.insert(qLLeg.end(), qRLeg.begin(), qRLeg.end());
  return qLLeg;
}
