#include "naoKinematics.h"
#include "Transform.h"
#include <math.h>
#include <stdio.h>

Transform rotYawPitchLeft(double a) {
  double ca = cos(a);
  double sa = sin(a);
  Transform t;
  t(0,0) = ca; t(0,1) = sa/SQRT2; t(0,2) = sa/SQRT2;
  t(1,0) = -sa/SQRT2; t(1,1) = .5*(1+ca); t(1,2) = .5*(-1+ca);
  t(2,0) = -sa/SQRT2; t(2,1) = .5*(-1+ca); t(2,2) = .5*(1+ca);
  return t;
}

Transform rotYawPitchRight(double a) {
  double ca = cos(a);
  double sa = sin(a);
  Transform t;
  t(0,0) = ca; t(0,1) = -sa/SQRT2; t(0,2) = sa/SQRT2;
  t(1,0) = sa/SQRT2; t(1,1) = .5*(1+ca); t(1,2) = .5*(1-ca);
  t(2,0) = -sa/SQRT2; t(2,1) = .5*(1-ca); t(2,2) = .5*(1+ca);
  return t;
}

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
nao_kinematics_forward_head(const double *q)
{
  Transform t;
  t = t.translateZ(neckOffsetZ)
    .mDH(0, 0, q[0], 0)
    .mDH(-PI/2, 0, -PI/2+q[1], 0)
    .rotateX(PI/2).rotateY(PI/2);
  return t;
}

Transform
nao_kinematics_forward_larm(const double *q)
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
nao_kinematics_forward_rarm(const double *q)
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
nao_kinematics_forward_lleg(const double *q)
{
  Transform t;
  t = t.translateY(hipOffsetY).translateZ(-hipOffsetZ)
    .mDH(-3*PI/4, 0, -PI/2+q[0], 0)
    .mDH(-PI/2, 0, PI/4+q[1], 0)
    .mDH(PI/2, 0, q[2], 0)
    .mDH(0, -thighLength, q[3], 0)
    .mDH(0, -tibiaLength, q[4], 0)
    .mDH(-PI/2, 0, q[5], 0)
    .rotateZ(PI).rotateY(-PI/2).translateZ(-footHeight);
  return t;
}

Transform
nao_kinematics_forward_rleg(const double *q)
{
  Transform t;
  t = t.translateY(-hipOffsetY).translateZ(-hipOffsetZ)
    .mDH(-PI/4, 0, -PI/2+q[0], 0)
    .mDH(-PI/2, 0, -PI/4+q[1], 0)
    .mDH(PI/2, 0, q[2], 0)
    .mDH(0, -thighLength, q[3], 0)
    .mDH(0, -tibiaLength, q[4], 0)
    .mDH(-PI/2, 0, q[5], 0)
    .rotateZ(PI).rotateY(-PI/2).translateZ(-footHeight);
  return t;
}

std::vector<double>
nao_kinematics_inverse_leg(
			   Transform trLeg,
			   int leg,
			   double hipYawPitch)
{
  std::vector<double> qLeg(6);
  bool left = (leg == LEG_LEFT); // Left leg
  bool calcHipYawPitch = (hipYawPitch > 0);

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

  if (calcHipYawPitch) {
    // Use hip rotation to calculate HipYawPitch
    Transform rHipT = trLeg;
    rHipT = rHipT.rotateX(-ankleRoll).rotateY(-anklePitch-kneePitch);
    if (left)
      hipYawPitch = atan2(SQRT2*rHipT(0,1),
			  rHipT(1,1)+rHipT(2,1));
    else
      hipYawPitch = atan2(-SQRT2*rHipT(0,1),
			  rHipT(1,1)-rHipT(2,1));
    //  printf("hipYawPitch = %g\n", hipYawPitch);
  }

  double xAnkle[3];
  xAnkle[0] = 0;
  xAnkle[1] = 0;
  xAnkle[2] = footHeight;
  trLeg.apply(xAnkle);
  for (int i = 0; i < 3; i++) {
    xAnkle[i] -= xHipOffset[i];
  }

  if (left) {
    inv(rotYawPitchLeft(hipYawPitch)).apply(xAnkle);
  }
  else {
    inv(rotYawPitchRight(hipYawPitch)).apply(xAnkle);
  }
  //  for (int i = 0; i < 3; i++) printf("xAnkle[%d] = %g\n", i, xAnkle[i]);

  double hipRoll = atan2(xAnkle[1], -xAnkle[2]);
  double pitch1 = asin(tibiaLength*sin(kneePitch)/lLeg);
  double hipPitch = asin(-xAnkle[0]/lLeg) - pitch1;

  qLeg[0] = hipYawPitch;
  qLeg[1] = hipRoll;
  qLeg[2] = hipPitch;
  qLeg[3] = kneePitch;
  qLeg[4] = anklePitch;
  qLeg[5] = ankleRoll;
  return qLeg;
}

std::vector<double>
nao_kinematics_inverse_lleg(
			   Transform trLeg,
			   double hipYawPitch)
{
  return nao_kinematics_inverse_leg(trLeg, LEG_LEFT, hipYawPitch);
}

std::vector<double>
nao_kinematics_inverse_rleg(
			   Transform trLeg,
			   double hipYawPitch)
{
  return nao_kinematics_inverse_leg(trLeg, LEG_RIGHT, hipYawPitch);
}

std::vector<double>
nao_kinematics_inverse_legs(
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

  double hipYawPitch = 0;
  if (legSupport == LEG_LEFT) {
    qLLeg = nao_kinematics_inverse_lleg(trTorso_LLeg);
    hipYawPitch = qLLeg[0];
    qRLeg = nao_kinematics_inverse_rleg(trTorso_RLeg, hipYawPitch);
  }
  else {
    qRLeg = nao_kinematics_inverse_rleg(trTorso_RLeg);
    hipYawPitch = qRLeg[0];
    qLLeg = nao_kinematics_inverse_lleg(trTorso_LLeg, hipYawPitch);
  }

  qLLeg.insert(qLLeg.end(), qRLeg.begin(), qRLeg.end());
  return qLLeg;
}


//SJ: toe/heel lifting leg IK 
//Simplified for flat terrain

std::vector<double> nao_kinematics_inverse_leg_toelift(
  Transform trLeg, int leg, double anklePitchCurrent,double toeliftMin){

  double aShiftX = 0.0;
  double aShiftY = 0.0;

  trLeg.rotateX(aShiftX).rotateY(aShiftY);

  Transform trInvLeg = inv(trLeg);

  // Hip Offset vector in Torso frame
  double xHipOffset[3];
  xHipOffset[0] = 0;
  xHipOffset[2] = -hipOffsetZ;
  if (leg == LEG_LEFT) xHipOffset[1] = hipOffsetY;
  else xHipOffset[1] = -hipOffsetY;

  // Hip Offset in Leg frame
  double xLeg[3];
  for (int i = 0; i < 3; i++) xLeg[i] = xHipOffset[i];
  trInvLeg.apply(xLeg);

//primary axes for the ground frame
  double vecx0 = cos(aShiftY);
  double vecx1 = 0;
  double vecx2 = sin(aShiftY);
  double vecz0 = sin(aShiftY)*cos(aShiftX);
  double vecz1 = -sin(aShiftX);
  double vecz2 = cos(aShiftY)*cos(aShiftX);

  //Relative ankle position in global frame (origin is the landing position)
  double dAnkle0 = footHeight*vecz0;
  double dAnkle1 = footHeight*vecz1;
  double dAnkle2 = footHeight*vecz2;

  //Find relative torso position from ankle position (in global frame)
  double xAnkle0 = xLeg[0] - dAnkle0;
  double xAnkle1 = xLeg[1] - dAnkle1;
  double xAnkle2 = xLeg[2] - dAnkle2;

  // Knee pitch
  double dLeg = xAnkle0*xAnkle0 + xAnkle1*xAnkle1 + xAnkle2*xAnkle2;
  double cKnee = .5*(dLeg-dTibia*dTibia-dThigh*dThigh)/(dTibia*dThigh);
  double ankle_tilt_angle = 0;
  double dLegMax = dTibia + dThigh;
  double footC = sqrt(footHeight*footHeight + footHeelX*footHeelX);
  double afootA = asin(footHeight/footC);

  if (dLeg>dLegMax*dLegMax) {

    //now we lift toe by x radian 
    //  new Ankle position in surface frame:
    //   (-heelX,0,0) + Fc*(cos(x+c),0,sin(x+c))
    // = (-heelX + Fc*cos(x+c),  0,   Fc*sin(x+c))

    //new ankle position (ax,ay,az) in global frame:
    // {  vecx0 * (-heelX + Fc*cos(x+c)) + vecz0* (Fc*sin(x+c)),
    //    vecx1 * (-heelX + Fc*cos(x+c)) + vecz1* (Fc*sin(x+c)),
    //    vecx2 * (-heelX + Fc*cos(x+c)) + vecz2* (Fc*sin(x+c)),
    // }

    // or 
    // {  -(vecx0 * heelX)  + vecx0*Fc*cos(b)+ vecz0*Fc*sin(b),
    //    -(vecx1 * heelX)  + vecx1*Fc*cos(b)+ vecz1*Fc*sin(b),
    //    -(vecx2 * heelX)  + vecx2*Fc*cos(b)+ vecz2*Fc*sin(b),
    // }

    // Leg distant constraint    
    // (xLeg[0]-ax)^2 + xLeg[1]^2 + (xLeg[2]-az)^2 = dLegMax^2

    // xLeg0Mod, yLeg0Mod, zLeg0Mod = xLeg[0]+vecx0*heelX, xLeg[1]+vecx1*heelX,xLeg[2]+vecx2*heelX
    // or 
    //  (xLeg0Mod - vecx0*Fc*cos(b) - vecz0*Fc*sin(b))^2 + 
    //  (xLeg1Mod - vecx1*Fc*cos(b) - vecz1*Fc*sin(b))^2 + 
    //  (xLeg2Mod - vecx2*Fc*cos(b) - vecz2*Fc*sin(b))^2 = dLegMax^2 
     
    // = (xLeg0Mod^2+xLeg1Mod^2+xLeg2Mod^2) + Fc^2 (vecx0^2+vecx1^2+vecx2^2) +
    //   - 2*Fc*cos(b) * (  xLeg0Mod*vecx0 + xLeg1Mod*vecx1 + xLeg2Mod*vecx2 ) +
    //   - 2*Fc*sin(b) * (  xLeg0Mod*vecz0 + xLeg1Mod*vecz1 + xLeg2Mod*vecz2 ) +    
    //   2*Fc*Fc*cos(b)sin(b)* (vecx0*vecz0 + vecx1*vecz1+ vecx2*vecz2)

  //   2*Fc*Fc*cos(b)sin(b)* (vecx0*vecz0 + vecx1*vecz1+ vecx2*vecz2)

    // eq: p*sinb + q*cosb + r* sinbcosb + s = 0

    double xLM0 = xLeg[0]+vecx0*footHeelX;
    double xLM1 = xLeg[1]+vecx1*footHeelX;
    double xLM2 = xLeg[2]+vecx2*footHeelX;

    double s2 = (xLM0*xLM0+xLM1*xLM1+xLM2*xLM2) + footC*footC*(vecx0*vecx0+vecx1*vecx1+vecx2*vecx2)- dLegMax*dLegMax;
    double p2 = -2*footC* (xLM0*vecz0 + xLM1*vecz1 + xLM2*vecz2);
    double q2 = -2*footC* (xLM0*vecx0 + xLM1*vecx1 + xLM2*vecx2);
    double r2 = 2*footC*footC*(vecx0*vecz0 + vecx1*vecz1+vecx2*vecz2);

  //newton method to find the solution
    double x0 = 0;
    double ferr=0;
    int iter_count=0;
    bool not_done=true; 
    while ((iter_count++<10) && not_done){
      ferr = p2*sin(x0)+q2*cos(x0)+r2*sin(x0)*cos(x0)+s2;
      double fdot = p2*cos(x0) - q2*sin(x0) + r2*cos(x0)*cos(x0) - r2*sin(x0)*sin(x0);
      x0 = x0 - ferr/fdot;
      if (fabs(ferr)<0.001) not_done=false;
    }  
    if (fabs(ferr)<0.01){ 
      ankle_tilt_angle = x0-afootA;
      printf("Toelift:%f\n",ankle_tilt_angle*180/3.1415);
    }
    else{
   //   printf("Toelift: no solution!\n");
      ankle_tilt_angle = 0;
    }
  //    if (ankle_tilt_angle<-45*3.1415/180)  ankle_tilt_angle=-45*3.1415/180;
  }

  //we can force tilt angle 
  if (ankle_tilt_angle<toeliftMin){
    ankle_tilt_angle=toeliftMin;
  }


  //lets calculate correct ankle offset position
  double dAnkle1Mod = vecx0*(-footHeelX + footC*cos(ankle_tilt_angle+afootA)) + vecz0*footC*sin(ankle_tilt_angle+afootA);
  double dAnkle2Mod = vecx1*(-footHeelX +  footC*cos(ankle_tilt_angle+afootA)) + vecz1*footC*sin(ankle_tilt_angle+afootA);
  double dAnkle3Mod = vecx2*(-footHeelX +  footC*cos(ankle_tilt_angle+afootA)) + vecz2*footC*sin(ankle_tilt_angle+afootA);      

  ankle_tilt_angle = -ankle_tilt_angle; //change into ankle PITCH bias angle

//Find relative torso position from ankle position (in global frame)
  xLeg[0] = xLeg[0] - dAnkle1Mod;
  xLeg[1] = xLeg[1] - dAnkle2Mod;
  xLeg[2] = xLeg[2] - dAnkle3Mod;

  dLeg = xLeg[0]*xLeg[0] + xLeg[1]*xLeg[1] + xLeg[2]*xLeg[2];
  cKnee = .5*(dLeg-dTibia*dTibia-dThigh*dThigh)/(dTibia*dThigh);

  if (cKnee > 1) cKnee = 1;
  if (cKnee < -1) cKnee = -1;
  double kneePitch = acos(cKnee);
  double kneeOffsetA=1;
  
  double kneePitchActual = kneePitch+aThigh*kneeOffsetA+aTibia*kneeOffsetA;

  //Now we know knee pitch and ankle tilt 
  Transform trAnkle =  trcopy (trLeg);

  //Body to Leg FK:
  //Trans(HIP).Rz(q0).Rx(q1).Ry(q2).Trans(UL).Ry(q3).Trans(LL).Ry(q4).Rx(q5).Trans(Foot)
  
  //Genertae body to ankle transform 
  trAnkle = trAnkle
    .translate(-footHeelX,0,0)
    .rotateY(ankle_tilt_angle)
    .translate(footHeelX,0,footHeight);

  //Get rid of hip offset to make hip to ankle transform
  Transform t;
  if (leg == LEG_LEFT){
    t=t.translate(0,-hipOffsetY,hipOffsetZ)*trAnkle;      
  }else{
    t=t.translate(0,hipOffsetY,hipOffsetZ)*trAnkle;
  }
  //then now t = Rz(q0).Rx(q1).Ry(q2).Trans(UL).Ry(q3).Trans(LL).Ry(q4).Rx(q5)
  //or     t_inv = Rx(-q5).Ry(-q4).   Trans(-LL).Ry(-q3).Trans(-UL)     .Ry(-q2).Rx(-q1).Rz(-q0)
  //       t_inv*(0 0 0 1)T  = Rx(-q5).Ry(-q4) * m * (0 0 0 1)T  
  Transform m;
  Transform tInv = inv(t);
  m=m.translate(kneeOffsetX,0,thighLength).rotateY(-kneePitchActual).translate(-kneeOffsetX,0,tibiaLength);

  //now lets solve for ankle pitch (q4) first
  // tInv(0,3) = m(0,3)*cos(q4) - m(2,3)*sin(q4)
  // (m0^2+m2^2)s^2 + 2t0 m2 s + t0^2 - m0^2 = 0

  double a = m(0,3)*m(0,3) + m(2,3)*m(2,3);
  double b = tInv(0,3) * m(2,3);
  double c = tInv(0,3)*tInv(0,3) - m(0,3)*m(0,3);
  double k = b*b-a*c;
  if (k<0) k=0;
  double s1 = (-b-sqrt(k))/a;
  double s2 = (-b+sqrt(k))/a;
  if (s1<-1) s1=-1;
  if (s2<-1) s2=-1;
  if (s1>1) s1=1;
  if (s2>1) s2=1;
  double anklePitch1 = asin(s1);
  double anklePitch2 = asin(s2);
  double err1 = tInv(0,3)-m(0,3)*cos(anklePitch1)+m(2,3)*sin(anklePitch1);
  double err2 = tInv(0,3)-m(0,3)*cos(anklePitch2)+m(2,3)*sin(anklePitch2);
  double anklePitchNew = anklePitch1;
  if (  (fabs(err1)<0.0001) && (fabs(err2)<0.0001) ) {
    //printf("Two solutions for anklepitch\n");
    double err_1 = fabs(anklePitchCurrent-anklePitch1);
    double err_2 = fabs(anklePitchCurrent-anklePitch2);
    if (err_2<err_1) {
      anklePitchNew = anklePitch2;
    }    
  }else{
    if (  (fabs(err1)<0.0001) || (fabs(err2)<0.0001) ) {
      if (fabs(err1)>fabs(err2)){
        anklePitchNew = anklePitch2;
      }
    }else{
      printf("NO VALID PITCH ANGLE!\n");

    }
  }
  


  //then now solve for ankle roll (q5)
  //tInv(1,3) = m0*sin(q4)* sin(q5) + m1*cos(q5) + m2*cos(q4)*sin(q5)
  //sin(q5) * (m0*sin(q4) + m2*cos(q4))  + m1*cos(q5) - tInv(1,3) = 0

  double p1 = m(0,3)*sin(anklePitchNew) + m(2,3)*cos(anklePitchNew);
  a = p1*p1+m(1,3)*m(1,3);
  b = -tInv(1,3)*p1;
  c = tInv(1,3)*tInv(1,3)-m(1,3)*m(1,3);
  k=b*b-a*c;
  if (k<0) k=0;
  s1 = (-b-sqrt(k))/a;
  s2 = (-b+sqrt(k))/a;
  if (s1<-1) s1=-1;
  if (s2<-1) s2=-1;
  if (s1>1) s1=1;
  if (s2>1) s2=1;
  double ankleRoll1 = asin(s1);
  double ankleRoll2 = asin(s2);
  err1 = tInv(1,3)-m(2,3)*cos(ankleRoll1)-p1*sin(ankleRoll1);
  err2 = tInv(1,3)-m(2,3)*cos(ankleRoll2)-p1*sin(ankleRoll2);
  double ankleRollNew = ankleRoll1;
  if (err1*err1>err2*err2) ankleRollNew = ankleRoll2;





  //Now we have ankle roll and pitch

//FOR STANDARD LEG
/*  
  //again, t = Rz(q0).Rx(q1).Ry(q2).Trans(UL).Ry(q3).Trans(LL).Ry(q4).Rx(q5)
  //lets get rid of knee and ankle rotations
  t=t.rotateX(-ankleRollNew).rotateY(-anklePitchNew-kneePitch);

  //now use ZXY euler angle equation to get q0,q1,q2
  double hipRollNew = asin(t(2,1));
  double hipYawNew = atan2(-t(0,1),t(1,1));
  double hipPitchNew = atan2(-t(2,0),t(2,2));
*/


//FOR NAO LEG
// t = Rzy(q0).Rx(q1).Ry(q2).Trans(UL).Ry(q3).Trans(LL).Ry(q4).Rx(q5)
//lets get rid of knee and ankle rotations
double hipYawPitchNew;

t=t.rotateX(-ankleRollNew).rotateY(-anklePitchNew-kneePitch);

Transform t2;
// now t = Ryz(q0).Rx(q1).Ry(q2).Trans(xxx)
if (leg == LEG_LEFT){ 
  hipYawPitchNew = atan2(SQRT2*t(0,1),t(1,1)+t(2,1));
  t2=inv(rotYawPitchLeft(hipYawPitchNew))*t;
}else{
  hipYawPitchNew = atan2(-SQRT2*t(0,1),t(1,1)-t(2,1));
  t2=inv(rotYawPitchRight(hipYawPitchNew))*t;
}
// now t=Rx(q1).Ry(q2).Trans(xxx)

//now use ZXY euler angle equation to get q1,q2
double hipRollNew = asin(t2(2,1));
double hipPitchNew = atan2(-t2(2,0),t2(2,2));


//NOW WE return ankle tilt angle too (using 7-sized array)
//  std::vector<double> qLeg(6);
  std::vector<double> qLeg(7);

//  qLeg[0] = hipYawNew;
  qLeg[0] = hipYawPitchNew; 
  qLeg[1] = hipRollNew;
  qLeg[2] = hipPitchNew;
  qLeg[3] = kneePitchActual;
  qLeg[4] = anklePitchNew;
  qLeg[5] = ankleRollNew;

  qLeg[6] = ankle_tilt_angle;

  return qLeg;
}




std::vector<double> nao_kinematics_inverse_leg_heellift(Transform trLeg, int leg, double anklePitchCurrent,double heelliftMin){

  double aShiftX = 0.0;
  double aShiftY = 0.0;

  trLeg.rotateX(aShiftX).rotateY(aShiftY);

  Transform trInvLeg = inv(trLeg);

  // Hip Offset vector in Torso frame
  double xHipOffset[3];
  xHipOffset[0] = 0;
  xHipOffset[2] = -hipOffsetZ;
  if (leg == LEG_LEFT) xHipOffset[1] = hipOffsetY;
  else xHipOffset[1] = -hipOffsetY;
  // Hip Offset in Leg frame
  double xLeg[3];
  for (int i = 0; i < 3; i++) xLeg[i] = xHipOffset[i];
  trInvLeg.apply(xLeg);

  //primary axes for the ground frame
  double vecx0 = cos(aShiftY);
  double vecx1 = 0;
  double vecx2 = sin(aShiftY);
  double vecz0 = sin(aShiftY)*cos(aShiftX);
  double vecz1 = -sin(aShiftX);
  double vecz2 = cos(aShiftY)*cos(aShiftX);

  //Relative ankle position in global frame (origin is the landing position)
  double dAnkle0 = footHeight*vecz0;
  double dAnkle1 = footHeight*vecz1;
  double dAnkle2 = footHeight*vecz2;

  //Find relative torso position from ankle position (in global frame)
  double xAnkle0 = xLeg[0] - dAnkle0;
  double xAnkle1 = xLeg[1] - dAnkle1;
  double xAnkle2 = xLeg[2] - dAnkle2;

  //Calculate the knee pitch
  double dLeg = xAnkle0*xAnkle0 + xAnkle1*xAnkle1 + xAnkle2*xAnkle2;
  double cKnee = .5*(dLeg-dTibia*dTibia-dThigh*dThigh)/(dTibia*dThigh);
  double ankle_tilt_angle = 0;
  double dLegMax = dTibia + dThigh;
  double footC = sqrt(footHeight*footHeight + footToeX*footToeX);
  double afootA = asin(footHeight/footC);

  if (dLeg>dLegMax*dLegMax) {
    //now we lift heel by x radian

    //  new Ankle position in surface frame:
    //   (toeX,0,0) - Fc*(cos(x+c),0,-sin(x+c))
    // = (toeX-Fc*cos(x+c),  0,   Fc*sin(x+c))

    //new ankle position (ax,ay,az) in global frame:
    // {  vecx0 * (toeX-Fc*cos(x+c)) + vecz0* (Fc*sin(x+c)),
    //    vecx1 * (toeX-Fc*cos(x+c)) + vecz1* (Fc*sin(x+c)),
    //    vecx2 * (toeX-Fc*cos(x+c)) + vecz2* (Fc*sin(x+c)),
    // }

    // or 
    // {  (vecx0 * toeX)    - vecx0*Fc*cos(b)+ vecz0*Fc*sin(b),
    //    (vecx1 * toeX)    - vecx1*Fc*cos(b)+ vecz1*Fc*sin(b),
    //    (vecx2 * toeX)    - vecx2*Fc*cos(b)+ vecz2*Fc*sin(b),
    // }

    // Leg distant constraint    
    // (xLeg[0]-ax)^2 + xLeg[1]^2 + (xLeg[2]-az)^2 = dLegMax^2

    // xLeg0Mod, yLeg0Mod, zLeg0Mod = xLeg[0]-vecx0*toeX, xLeg[1]-vecx1*toeX,xLeg[2]-vecx2*toeX
    // or 
    //  (xLeg0Mod + vecx0*Fc*cos(b) - vecz0*Fc*sin(b))^2 + 
    //  (xLeg1Mod + vecx1*Fc*cos(b) - vecz1*Fc*sin(b))^2 + 
    //  (xLeg2Mod + vecx2*Fc*cos(b) - vecz2*Fc*sin(b))^2 = dLegMax^2 
     
    // = (xLeg0Mod^2+xLeg1Mod^2+xLeg2Mod^2) + Fc^2 (vecx0^2+vecx1^2+vecx2^2) +
    //   2*Fc*cos(b) * (  xLeg0Mod*vecx0 + xLeg1Mod*vecx1 + xLeg2Mod*vecx2 ) +
    //   - 2*Fc*sin(b) * (  xLeg0Mod*vecz0 + xLeg1Mod*vecz1 + xLeg2Mod*vecz2 ) +    
    //   2*Fc*Fc*cos(b)sin(b)* (vecx0*vecz0 + vecx1*vecz1+ vecx2*vecz2)

    // eq: p*sinb + q*cosb + r* sinbcosb + s = 0
    double xLM0 = xLeg[0]-vecx0*footToeX;
    double xLM1 = xLeg[1]-vecx1*footToeX;
    double xLM2 = xLeg[2]-vecx2*footToeX;
    double s2 = (xLM0*xLM0+xLM1*xLM1+xLM2*xLM2) + footC*footC*(vecx0*vecx0+vecx1*vecx1+vecx2*vecx2)- dLegMax*dLegMax;
    double p2 = -2*footC* (xLM0*vecz0 + xLM1*vecz1 + xLM2*vecz2);
    double q2 = 2*footC* (xLM0*vecx0 + xLM1*vecx1 + xLM2*vecx2);
    double r2 = 2*footC*footC*(vecx0*vecz0 + vecx1*vecz1+vecx2*vecz2);

  //newton method to find the solution
    double x0 = 0;
    double ferr=0;
    int iter_count=0;
    bool not_done=true; 
    while ((iter_count++<10) && not_done){
      ferr = p2*sin(x0)+q2*cos(x0)+r2*sin(x0)*cos(x0)+s2;
      double fdot = p2*cos(x0) - q2*sin(x0) + r2*cos(x0)*cos(x0) - r2*sin(x0)*sin(x0);
      x0 = x0 - ferr/fdot;
      if (fabs(ferr)<0.001) not_done=false;
    }  
    if (fabs(ferr)<0.01){ankle_tilt_angle = x0-afootA;
      printf("Heellift:%f\n",ankle_tilt_angle*180/3.1415);
  
    }
    else{ankle_tilt_angle = 0;}
  }
  //now we know ankle tilt ankle



  //we can force tilt angle
  if (ankle_tilt_angle<heelliftMin){
    ankle_tilt_angle=heelliftMin;
  }



  //lets calculate correct ankle offset position
  double dAnkle1Mod = vecx0*(footToeX - footC*cos(ankle_tilt_angle+afootA)) + vecz0*footC*sin(ankle_tilt_angle+afootA);
  double dAnkle2Mod = vecx1*(footToeX - footC*cos(ankle_tilt_angle+afootA)) + vecz1*footC*sin(ankle_tilt_angle+afootA);
  double dAnkle3Mod = vecx2*(footToeX - footC*cos(ankle_tilt_angle+afootA)) + vecz2*footC*sin(ankle_tilt_angle+afootA);

//Find relative torso position from ankle position (in global frame)
  xLeg[0] = xLeg[0] - dAnkle1Mod;
  xLeg[1] = xLeg[1] - dAnkle2Mod;
  xLeg[2] = xLeg[2] - dAnkle3Mod;

  dLeg = xLeg[0]*xLeg[0] + xLeg[1]*xLeg[1] + xLeg[2]*xLeg[2];
  cKnee = .5*(dLeg-dTibia*dTibia-dThigh*dThigh)/(dTibia*dThigh);



  if (cKnee > 1) cKnee = 1;
  if (cKnee < -1) cKnee = -1;
  double kneePitch = acos(cKnee);
  double kneeOffsetA=1;  
  double kneePitchActual = kneePitch+aThigh*kneeOffsetA+aTibia*kneeOffsetA;


  //Now we know knee pitch and ankle tilt 
  Transform trAnkle =  trcopy (trLeg);

  //Body to Leg FK:
  //Trans(HIP).Rz(q0).Rx(q1).Ry(q2).Trans(UL).Ry(q3).Trans(LL).Ry(q4).Rx(q5).Trans(Foot)
  
  //Genertae body to ankle transform 
  trAnkle = trAnkle
    .translate(footToeX,0,0)
    .rotateY(ankle_tilt_angle)
    .translate(-footToeX,0,footHeight);

  //Get rid of hip offset to make hip to ankle transform
  Transform t;
  if (leg == LEG_LEFT){
    t=t.translate(0,-hipOffsetY,hipOffsetZ)*trAnkle;      
  }else{
    t=t.translate(0,hipOffsetY,hipOffsetZ)*trAnkle;
  }
  //then now t = Rz(q0).Rx(q1).Ry(q2).Trans(UL).Ry(q3).Trans(LL).Ry(q4).Rx(q5)
  //or     t_inv = Rx(-q5).Ry(-q4).   Trans(-LL).Ry(-q3).Trans(-UL)     .Ry(-q2).Rx(-q1).Rz(-q0)
  //       t_inv*(0 0 0 1)T  = Rx(-q5).Ry(-q4) * m * (0 0 0 1)T  
  Transform m;
  Transform tInv = inv(t);
  m=m.translate(kneeOffsetX,0,thighLength).rotateY(-kneePitchActual).translate(-kneeOffsetX,0,tibiaLength);

  //now lets solve for ankle pitch (q4) first
  // tInv(0,3) = m(0,3)*cos(q4) - m(2,3)*sin(q4)
  // (m0^2+m2^2)s^2 + 2t0 m2 s + t0^2 - m0^2 = 0

  double a = m(0,3)*m(0,3) + m(2,3)*m(2,3);
  double b = tInv(0,3) * m(2,3);
  double c = tInv(0,3)*tInv(0,3) - m(0,3)*m(0,3);
  double k = b*b-a*c;
  if (k<0) k=0;
  double s1 = (-b-sqrt(k))/a;
  double s2 = (-b+sqrt(k))/a;
  if (s1<-1) s1=-1;
  if (s2<-1) s2=-1;
  if (s1>1) s1=1;
  if (s2>1) s2=1;
  double anklePitch1 = asin(s1);
  double anklePitch2 = asin(s2);
  double err1 = tInv(0,3)-m(0,3)*cos(anklePitch1)+m(2,3)*sin(anklePitch1);
  double err2 = tInv(0,3)-m(0,3)*cos(anklePitch2)+m(2,3)*sin(anklePitch2);
  double anklePitchNew = anklePitch1;  
  if (  (fabs(err1)<0.0001) && (fabs(err2)<0.0001) ) {
    //printf("Two solutions for anklepitch\n");
    double err_1 = fabs(anklePitchCurrent-anklePitch1);
    double err_2 = fabs(anklePitchCurrent-anklePitch2);
    if (err_2<err_1) {
      anklePitchNew = anklePitch2;
    }    
  }else{
    if (fabs(err1)>fabs(err2)){
      anklePitchNew = anklePitch2;
    }
  }
   

  //then now solve for ankle roll (q5)
  //tInv(1,3) = m0*sin(q4)* sin(q5) + m1*cos(q5) + m2*cos(q4)*sin(q5)
  //sin(q5) * (m0*sin(q4) + m2*cos(q4))  + m1*cos(q5) - tInv(1,3) = 0
  double p1 = m(0,3)*sin(anklePitchNew) + m(2,3)*cos(anklePitchNew);
  a = p1*p1+m(1,3)*m(1,3);
  b = -tInv(1,3)*p1;
  c = tInv(1,3)*tInv(1,3)-m(1,3)*m(1,3);
  k=b*b-a*c;
  if (k<0) k=0;
  s1 = (-b-sqrt(k))/a;
  s2 = (-b+sqrt(k))/a;
  if (s1<-1) s1=-1;
  if (s2<-1) s2=-1;
  if (s1>1) s1=1;
  if (s2>1) s2=1;
  double ankleRoll1 = asin(s1);
  double ankleRoll2 = asin(s2);
  double err3 = tInv(1,3)-m(2,3)*cos(ankleRoll1)-p1*sin(ankleRoll1);
  double err4 = tInv(1,3)-m(2,3)*cos(ankleRoll2)-p1*sin(ankleRoll2);
  double ankleRollNew = ankleRoll1;
  if (fabs(err3)>fabs(err4)){ankleRollNew = ankleRoll2;}


  //Now we have ankle roll and pitch

//FOR STANDARD LEG
/*  
  //again, t = Rz(q0).Rx(q1).Ry(q2).Trans(UL).Ry(q3).Trans(LL).Ry(q4).Rx(q5)
  //lets get rid of knee and ankle rotations
  t=t.rotateX(-ankleRollNew).rotateY(-anklePitchNew-kneePitch);

  //now use ZXY euler angle equation to get q0,q1,q2
  double hipRollNew = asin(t(2,1));
  double hipYawNew = atan2(-t(0,1),t(1,1));
  double hipPitchNew = atan2(-t(2,0),t(2,2));
*/


//FOR NAO LEG
// t = Rzy(q0).Rx(q1).Ry(q2).Trans(UL).Ry(q3).Trans(LL).Ry(q4).Rx(q5)
//lets get rid of knee and ankle rotations
double hipYawPitchNew;

t=t.rotateX(-ankleRollNew).rotateY(-anklePitchNew-kneePitch);

Transform t2;
// now t = Ryz(q0).Rx(q1).Ry(q2).Trans(xxx)
if (leg == LEG_LEFT){ 
  hipYawPitchNew = atan2(SQRT2*t(0,1),t(1,1)+t(2,1));
  t2=inv(rotYawPitchLeft(hipYawPitchNew))*t;
}else{
  hipYawPitchNew = atan2(-SQRT2*t(0,1),t(1,1)-t(2,1));
  t2=inv(rotYawPitchRight(hipYawPitchNew))*t;
}
// now t=Rx(q1).Ry(q2).Trans(xxx)

//now use ZXY euler angle equation to get q1,q2
double hipRollNew = asin(t2(2,1));
double hipPitchNew = atan2(-t2(2,0),t2(2,2));


//NOW WE return ankle tilt angle too (using 7-sized array)
//  std::vector<double> qLeg(6);
  std::vector<double> qLeg(7);

//  qLeg[0] = hipYawNew;
  qLeg[0] = hipYawPitchNew; 
  qLeg[1] = hipRollNew;
  qLeg[2] = hipPitchNew;
  qLeg[3] = kneePitchActual;
  qLeg[4] = anklePitchNew;
  qLeg[5] = ankleRollNew;

  qLeg[6] = ankle_tilt_angle;
  return qLeg;
}





std::vector<double>
nao_kinematics_calculate_com_positions(
    const double *qLArm,const double *qRArm,const double *qLLeg,const double *qRLeg,const double *qHead    
    ){
  
  
  Transform 
    tTorso, 
    tNeck, tHead,

//    tLArm0, tLArm1, tLArm2, tLArm3, tLArm4, tLArm5, tLArm6,
//    tRArm0, tRArm1, tRArm2, tRArm3, tRArm4, tRArm5, tRArm6,

    tLLeg0, tLLeg1, tLLeg2, tLLeg3, tLLeg4, tLLeg5,
    tRLeg0, tRLeg1, tRLeg2, tRLeg3, tRLeg4, tRLeg5,
    
    tBody0, tBody1, tBody2
    ;
    
  //COM is calculated based on TORSO frame
  //for birdwalk, the frame is flipped and x,y positions are negated
  

/*
  tLArm0= trcopy(tTorso).translate(armLinkL[0])
          .rotateY(qLArm[0]);

  tLArm1= trcopy(tTorso).translate(armLinkL[0])
          .rotateY(qLArm[0]).rotateZ(qLArm[1])
          .translate(armComL[1]);

  tLArm2= trcopy(tTorso).translate(armLinkL[0])
          .rotateY(qLArm[0]).rotateZ(qLArm[1])
          .translate(armLinkL[2]).rotateX(qLArm[2])
          .translate(armComL[2]);

  tLArm3= trcopy(tTorso).translate(armLinkL[0])
          .rotateY(qLArm[0]).rotateZ(qLArm[1])
          .translate(armLinkL[2]).rotateX(qLArm[2])
          .translate(armLinkL[3]).rotateY(qLArm[3])
          .translate(armComL[3]);

  tLArm4= trcopy(tTorso).translate(armLinkL[0])
          .rotateY(qLArm[0]).rotateZ(qLArm[1])
          .translate(armLinkL[2]).rotateX(qLArm[2])
          .translate(armLinkL[3]).rotateY(qLArm[3])
          .translate(armLinkL[4]).rotateX(qLArm[4])
          .translate(armComL[4]);

  tLArm5= trcopy(tTorso).translate(armLinkL[0])
          .rotateY(qLArm[0]).rotateZ(qLArm[1])
          .translate(armLinkL[2]).rotateX(qLArm[2])
          .translate(armLinkL[3]).rotateY(qLArm[3])
          .translate(armLinkL[4]).rotateX(qLArm[4])
          .rotateZ(qLArm[5]).translate(armComL[5]);

  tLArm6= trcopy(tTorso).translate(armLinkL[0])
          .rotateY(qLArm[0]).rotateZ(qLArm[1])
          .translate(armLinkL[2]).rotateX(qLArm[2])
          .translate(armLinkL[3]).rotateY(qLArm[3])
          .translate(armLinkL[4]).rotateX(qLArm[4])
          .rotateZ(qLArm[5]).rotateX(qLArm[6])
          .translate(armComL[6]);


  tRArm0= trcopy(tTorso).translate(armLinkR[0])
          .rotateY(qRArm[0]);          

  tRArm1= trcopy(tTorso).translate(armLinkR[0])
          .rotateY(qRArm[0]).rotateZ(qRArm[1])
          .translate(armComR[1]);

  tRArm2= trcopy(tTorso).translate(armLinkR[0])
          .rotateY(qRArm[0]).rotateZ(qRArm[1])
          .translate(armLinkR[2]).rotateX(qRArm[2])
          .translate(armComR[2]);

  tRArm3= trcopy(tTorso).translate(armLinkR[0])
          .rotateY(qRArm[0]).rotateZ(qRArm[1])
          .translate(armLinkR[2]).rotateX(qRArm[2])
          .translate(armLinkR[3]).rotateY(qRArm[3])
          .translate(armComR[3]);

  tRArm4= trcopy(tTorso).translate(armLinkR[0])
          .rotateY(qRArm[0]).rotateZ(qRArm[1])
          .translate(armLinkR[2]).rotateX(qRArm[2])
          .translate(armLinkR[3]).rotateY(qRArm[3])
          .translate(armLinkR[4]).rotateX(qRArm[4])
          .translate(armComR[4]);          

  tRArm5= trcopy(tTorso).translate(armLinkR[0])
          .rotateY(qRArm[0]).rotateZ(qRArm[1])
          .translate(armLinkR[2]).rotateX(qRArm[2])
          .translate(armLinkR[3]).rotateY(qRArm[3])
          .translate(armLinkR[4]).rotateX(qRArm[4])
          .rotateZ(qRArm[5]).translate(armComR[5]);

  tRArm6= trcopy(tTorso).translate(armLinkR[0])
          .rotateY(qRArm[0]).rotateZ(qRArm[1])
          .translate(armLinkR[2]).rotateX(qRArm[2])
          .translate(armLinkR[3]).rotateY(qRArm[3])
          .translate(armLinkR[4]).rotateX(qRArm[4])
          .rotateZ(qRArm[5]).rotateX(qRArm[6])
          .translate(armComR[6]);
*/

  Transform tLeftHip1 = 
    trcopy(tTorso).translate(llegLink0)*rotYawPitchLeft(qLLeg[0]);

  Transform tRightHip1 = 
    trcopy(tTorso).translate(rlegLink0)*rotYawPitchRight(qRLeg[0]);


  tLLeg0 = trcopy(tLeftHip1)
          .translate(legComL[0]);

  tLLeg1 = trcopy(tLeftHip1).rotateX(qLLeg[1])
          .translate(legComL[1]);

  tLLeg2 = trcopy(tLeftHip1).rotateX(qLLeg[1]).rotateY(qLLeg[2])
          .translate(legComL[2]);

  tLLeg3 = trcopy(tLeftHip1).rotateX(qLLeg[1]).rotateY(qLLeg[2])
          .translate(legLink[3]).rotateY(qLLeg[3])
          .translate(legComL[3]);

  tLLeg4 = trcopy(tLeftHip1).rotateX(qLLeg[1]).rotateY(qLLeg[2])
          .translate(legLink[3]).rotateY(qLLeg[3])
          .translate(legLink[4]).rotateY(qLLeg[4])
          .translate(legComL[4]);

  tLLeg5 = trcopy(tLeftHip1).rotateX(qLLeg[1]).rotateY(qLLeg[2])
          .translate(legLink[3]).rotateY(qLLeg[3])
          .translate(legLink[4]).rotateY(qLLeg[4])
          .translate(legLink[5]).rotateY(qLLeg[5])
          .translate(legComL[5]);


  tRLeg0 = trcopy(tRightHip1)
          .translate(legComR[0]);

  tRLeg1 = trcopy(tRightHip1).rotateX(qRLeg[1])
          .translate(legComR[1]);

  tRLeg2 = trcopy(tRightHip1).rotateX(qRLeg[1]).rotateY(qRLeg[2])
          .translate(legComR[2]);

  tRLeg3 = trcopy(tRightHip1).rotateX(qRLeg[1]).rotateY(qRLeg[2])
          .translate(legLink[3]).rotateY(qRLeg[3])
          .translate(legComR[3]);

  tRLeg4 = trcopy(tRightHip1).rotateX(qRLeg[1]).rotateY(qRLeg[2])
          .translate(legLink[3]).rotateY(qRLeg[3])
          .translate(legLink[4]).rotateY(qRLeg[4])
          .translate(legComR[4]);

  tRLeg5 = trcopy(tRightHip1).rotateX(qLLeg[1]).rotateY(qLLeg[2])
          .translate(legLink[3]).rotateY(qRLeg[3])
          .translate(legLink[4]).rotateY(qRLeg[4])
          .translate(legLink[5]).rotateY(qRLeg[5])
          .translate(legComR[5]);


  /////////////////////////////////
  tBody0 = trcopy(tTorso)
          .translate(bodyCom[0]);

  tBody1 = trcopy(tTorso).translate(0,0,neckOffsetZ)
          .rotateZ(qHead[0])
          .translate(bodyCom[1]);

  tBody2 = trcopy(tTorso).translate(0,0,neckOffsetZ)
          .rotateZ(qHead[0]).rotateY(qHead[1])
          .translate(bodyCom[2]);

  
  


//make a single compound COM position (from pelvis frame)
  std::vector<double> r(4);


  double use_lleg = 1.0;
  double use_rleg = 1.0;

 r[0] = 
         MassBody[0] * tBody0(0,3) +
         MassBody[1] * tBody1(0,3) +
         MassBody[2] * tBody2(0,3) +
  /*       
         MassArmL[0]* tLArm0(0,3)+  MassArmR[0]*tRArm0(0,3) +
         MassArmL[1]* tLArm1(0,3)+  MassArmR[1]*tRArm1(0,3) +
         MassArmL[2]* tLArm2(0,3)+  MassArmR[2]*tRArm2(0,3) +
         MassArmL[3]* tLArm3(0,3)+  MassArmR[3]*tRArm3(0,3) +
         MassArmL[4]* tLArm4(0,3)+  MassArmR[4]*tRArm4(0,3) +
         MassArmL[5]* tLArm5(0,3)+  MassArmR[5]*tRArm5(0,3) +
         MassArmL[6]* tLArm6(0,3)+  MassArmR[6]*tRArm6(0,3) +
*/

         MassLeg[0]* (tLLeg0(0,3)*use_lleg+tRLeg0(0,3)*use_rleg)+
         MassLeg[1]* (tLLeg1(0,3)*use_lleg+tRLeg1(0,3)*use_rleg)+
         MassLeg[2]* (tLLeg2(0,3)*use_lleg+tRLeg2(0,3)*use_rleg)+
         MassLeg[3]* (tLLeg3(0,3)*use_lleg+tRLeg3(0,3)*use_rleg)+
         MassLeg[4]* (tLLeg4(0,3)*use_lleg+tRLeg4(0,3)*use_rleg)+
         MassLeg[5]* (tLLeg5(0,3)*use_lleg+tRLeg5(0,3)*use_rleg);


  r[1] = 
         MassBody[0] * tBody0(1,3) +
         MassBody[1] * tBody1(1,3) +
         MassBody[2] * tBody2(1,3) +

/*
         MassArmL[0]* tLArm0(1,3)+  MassArmR[0]*tRArm0(1,3) +
         MassArmL[1]* tLArm1(1,3)+  MassArmR[1]*tRArm1(1,3) +
         MassArmL[2]* tLArm2(1,3)+  MassArmR[2]*tRArm2(1,3) +
         MassArmL[3]* tLArm3(1,3)+  MassArmR[3]*tRArm3(1,3) +
         MassArmL[4]* tLArm4(1,3)+  MassArmR[4]*tRArm4(1,3) +
         MassArmL[5]* tLArm5(1,3)+  MassArmR[5]*tRArm5(1,3) +
         MassArmL[6]* tLArm6(1,3)+  MassArmR[6]*tRArm6(1,3) +
  */       

  
         MassLeg[0]* (tLLeg0(1,3)*use_lleg+tRLeg0(1,3)*use_rleg)+
         MassLeg[1]* (tLLeg1(1,3)*use_lleg+tRLeg1(1,3)*use_rleg)+
         MassLeg[2]* (tLLeg2(1,3)*use_lleg+tRLeg2(1,3)*use_rleg)+
         MassLeg[3]* (tLLeg3(1,3)*use_lleg+tRLeg3(1,3)*use_rleg)+
         MassLeg[4]* (tLLeg4(1,3)*use_lleg+tRLeg4(1,3)*use_rleg)+
         MassLeg[5]* (tLLeg5(1,3)*use_lleg+tRLeg5(1,3)*use_rleg);

  r[2] = 
         MassBody[0] * tBody0(2,3) +
         MassBody[1] * tBody1(2,3) +
         MassBody[2] * tBody2(2,3) +

/*
         MassArmL[0]* tLArm0(2,3)+  MassArmR[0]*tRArm0(2,3) +
         MassArmL[1]* tLArm1(2,3)+  MassArmR[1]*tRArm1(2,3) +
         MassArmL[2]* tLArm2(2,3)+  MassArmR[2]*tRArm2(2,3) +
         MassArmL[3]* tLArm3(2,3)+  MassArmR[3]*tRArm3(2,3) +
         MassArmL[4]* tLArm4(2,3)+  MassArmR[4]*tRArm4(2,3) +
         MassArmL[5]* tLArm5(2,3)+  MassArmR[5]*tRArm5(2,3) +
         MassArmL[6]* tLArm6(2,3)+  MassArmR[6]*tRArm6(2,3) +
*/
  
         MassLeg[0]* (tLLeg0(2,3)*use_lleg+tRLeg0(2,3)*use_rleg)+
         MassLeg[1]* (tLLeg1(2,3)*use_lleg+tRLeg1(2,3)*use_rleg)+
         MassLeg[2]* (tLLeg2(2,3)*use_lleg+tRLeg2(2,3)*use_rleg)+
         MassLeg[3]* (tLLeg3(2,3)*use_lleg+tRLeg3(2,3)*use_rleg)+
         MassLeg[4]* (tLLeg4(2,3)*use_lleg+tRLeg4(2,3)*use_rleg)+
         MassLeg[5]* (tLLeg5(2,3)*use_lleg+tRLeg5(2,3)*use_rleg);

  int i;

  r[3] = MassBody[0]+MassBody[1]+MassBody[2];
  //for (i=0;i<7;i++) r[3]+=MassArmL[i]+MassArmR[i];
  for (i=0;i<6;i++) r[3]+=(use_lleg+use_rleg)*MassLeg[i];

  return r;
}


std::vector<double>
nao_kinematics_calculate_com_positions(const double *qLLeg,const double *qRLeg){
  const double qHead[2]={0.0,0.0};
  const double qLArm[4]={0.0,0.0,0.0,0.0};
  const double qRArm[4]={0.0,0.0,0.0,0.0};
  return nao_kinematics_calculate_com_positions(
    &qLArm[0], &qRArm[0], &qLLeg[0], &qRLeg[0], &qHead[0]);
}
