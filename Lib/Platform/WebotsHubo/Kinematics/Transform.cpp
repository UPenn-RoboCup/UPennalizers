#include "Transform.h"
#include <math.h>

Transform::Transform() {
  clear();
}

void Transform::clear() {
  // Initialize to identity matrix:
  for (int i = 0; i < 4; i++)
    for (int j = 0; j < 4; j++)
      t[i][j] = 0;

  t[0][0] = 1;
  t[1][1] = 1;
  t[2][2] = 1;
  t[3][3] = 1;
}

Transform& Transform::translate(double x, double y, double z) {
  t[0][3] += t[0][0]*x + t[0][1]*y + t[0][2]*z;
  t[1][3] += t[1][0]*x + t[1][1]*y + t[1][2]*z;
  t[2][3] += t[2][0]*x + t[2][1]*y + t[2][2]*z;
  return *this;
}

Transform& Transform::translateX(double x) {
  t[0][3] += t[0][0]*x;
  t[1][3] += t[1][0]*x;
  t[2][3] += t[2][0]*x;
  return *this;
}

Transform& Transform::translateY(double y) {
  t[0][3] += t[0][1]*y;
  t[1][3] += t[1][1]*y;
  t[2][3] += t[2][1]*y;
  return *this;
}

Transform& Transform::translateZ(double z) {
  t[0][3] += t[0][2]*z;
  t[1][3] += t[1][2]*z;
  t[2][3] += t[2][2]*z;
  return *this;
}

Transform& Transform::rotateX(double a) {
  double ca = cos(a);
  double sa = sin(a);
  for (int i = 0; i < 3; i++) {
    double ty = t[i][1];
    double tz = t[i][2];
    t[i][1] = ca*ty + sa*tz;
    t[i][2] = -sa*ty + ca*tz;
  }
  return *this;
}

Transform& Transform::rotateY(double a) {
  double ca = cos(a);
  double sa = sin(a);
  for (int i = 0; i < 3; i++) {
    double tx = t[i][0];
    double tz = t[i][2];
    t[i][0] = ca*tx - sa*tz;
    t[i][2] = sa*tx + ca*tz;
  }
  return *this;
}

Transform& Transform::rotateZ(double a) {
  double ca = cos(a);
  double sa = sin(a);
  for (int i = 0; i < 3; i++) {
    double tx = t[i][0];
    double ty = t[i][1];
    t[i][0] = ca*tx + sa*ty;
    t[i][1] = -sa*tx + ca*ty;
  }
  return *this;
}

Transform& Transform::mDH(double alpha, double a, double theta, double d) {
  /*
  Transform t1;
  double ca = cos(alpha);
  double sa = sin(alpha);
  double ct = cos(theta);
  double st = sin(theta);
  t1(0,0) = ct; t1(0,1) = -st; t1(0,2) = 0; t1(0,3) = a;
  t1(1,0) = st*ca; t1(1,1) = ct*ca; t1(1,2) = -sa; t1(1,3) = -sa*d;
  t1(2,0) = st*sa; t1(2,1) = ct*sa; t1(2,2) = ca; t1(2,3) = ca*d;
  */

  this->translateX(a).rotateX(alpha).translateZ(d).rotateZ(theta);
  return *this;
}

void Transform::apply(double x[3]) {
  double x0[3];
  for (int i = 0; i < 3; i++) {
    x0[i] = x[i];
  }
  for (int i = 0; i < 3; i++) {
    x[i] = t[i][3];
    for (int j = 0; j < 3; j++) {
      x[i] += t[i][j]*x0[j];
    }
  }
}

double const Transform::operator() (int i, int j) const {
  return t[i][j];
}

double& Transform::operator() (int i, int j) {
  return t[i][j];
}

Transform operator* (const Transform &t1, const Transform &t2) {
  Transform t;
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 4; j++) {
      t(i,j) = t1(i,0)*t2(0,j) + t1(i,1)*t2(1,j) +
	t1(i,2)*t2(2,j) + t1(i,3)*t2(3,j);
    }
  }
  return t;
}

Transform inv (const Transform &t1) {
  Transform t;
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      // Transpose rotation:
      t(i,j) = t1(j,i);
      // Compute inv translation:
      t(i,3) -= t1(j,i)*t1(j,3);
    }
  }
  return t;
}

Transform transform6D(const double p[6]) {
  Transform t;
  //  t = t.translate(p[0],p[1],p[2]).rotateZ(p[5]).rotateY(p[4]).rotateX(p[3]);

  double cwx = cos(p[3]);
  double swx = sin(p[3]);
  double cwy = cos(p[4]);
  double swy = sin(p[4]);
  double cwz = cos(p[5]);
  double swz = sin(p[5]);
  t(0,0) = cwy*cwz;
  t(0,1) = swx*swy*cwz-cwx*swz;
  t(0,2) = cwx*swy*cwz+swx*swz;
  t(0,3) = p[0];
  t(1,0) = cwy*swz;
  t(1,1) = swx*swy*swz+cwx*cwz;
  t(1,2) = cwx*swy*swz-swx*cwz;
  t(1,3) = p[1];
  t(2,0) = -swy;
  t(2,1) = swx*cwy;
  t(2,2) = cwx*cwy;
  t(2,3) = p[2];
  return t;
}

std::vector<double> position6D(const Transform &t1) {
  std::vector<double> p(6);
  p[0] = t1(0,3);
  p[1] = t1(1,3);
  p[2] = t1(2,3);
  p[3] = atan2(t1(2,1), t1(2,2));
  p[4] = -asin(t1(2,0));
  p[5] = atan2(t1(1,0), t1(0,0));
  return p;
}
