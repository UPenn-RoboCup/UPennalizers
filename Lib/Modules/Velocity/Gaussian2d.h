#ifndef GAUSSIAN2D_H
#define GAUSSIAN2D_H

#include <math.h>

#ifndef PI
#define PI M_PI
#endif

const double DEFAULT_VAR = 1E8;
const double EPS = .1/(DEFAULT_VAR*DEFAULT_VAR);

class Gaussian2d {
 public:
  Gaussian2d() {
    clear();
    setLogAmplitude(0);
  }
  Gaussian2d(int x, int y) {
    clear();
    setMean(x,y);
    setLogAmplitude(0);
  }
  
  void clear() {
    x = y = 0;
    cxx = cyy = DEFAULT_VAR;
    cxy = 0;
    cDet = cxx*cyy-cxy*cxy;
    a0 = 0;
  }

  void getMean(double &vx, double &vy) {
    vx = x; vy = y;
  }

  void getCovariance(double &vxx, double &vyy, double &vxy) {
    vxx = cxx;
    vyy = cyy;
    vxy = cxy;
  }

  void getCovarianceAxis(double &s1, double &s2, double &alpha) {
    double cTrace = cxx+cyy;
    double qFactor = sqrt(cTrace*cTrace-4*cDet);

    s1 = .5*(cTrace-qFactor);
    s2 = .5*(cTrace+qFactor);

    if ((cxy == 0) && (cxx == cyy))
      alpha = 0;
    else {
      alpha = atan2(cxx-cxy-s1, cyy-cxy-s1);
    }

    s1 = sqrt(s1);
    s2 = sqrt(s2);
  }

  double getLogAmplitude() { return a0; }

  /*
  double getLogLikelihood(double vx, double vy) {
    double dx = vx-x, dy = vy-y;

    double axx = cyy/cDet;
    double ayy = cxx/cDet;
    double axy = -cxy/cDet;
    
    return -.5*(axx*dx*dx+ayy*dy*dy+2*axy*dx*dy);
  }
  */

  double getError() {
    double cTrace = cxx+cyy;
    return sqrt(cTrace);
  }

  void setMean(double vx, double vy) {
    x = vx; y = vy;
  }

  void checkCovariance(void) {
    if ((cxx <= 0) ||
	(cxx > DEFAULT_VAR) ||
	(cyy <= 0) ||
	(cyy > DEFAULT_VAR)) {
      cxx = DEFAULT_VAR;
      cyy = DEFAULT_VAR;
      cxy = 0;
    }

    cDet = cxx*cyy-cxy*cxy;
    if (cDet < EPS) {
//      cerr << "Bad variance in Gaussian2d::setCovariance." << endl;
      double t = (1-cDet)/(cxx+cyy);
      cxx += t;
      cyy += t;
      cDet = cxx*cyy-cxy*cxy;
    }
  }

  void setCovariance(double vxx, double vyy, double vxy) {
    cxx = vxx;
    cyy = vyy;
    cxy = vxy;

    checkCovariance();
  }

  void setCovarianceAxis(double s1, double s2, double alpha) {
    s1 = s1*s1;
    s2 = s2*s2;

    double cosa = cos(alpha);
    double sina = sin(alpha);
    cxx = s1*cosa*cosa+s2*sina*sina;
    cyy = s1*sina*sina+s2*cosa*cosa;
    cxy = (s1-s2)*cosa*sina;

    checkCovariance();
  }

  void addToCovariance(double sigma) {
    cxx += sigma*sigma;
    cyy += sigma*sigma;

    checkCovariance();
  }

  void setLogAmplitude(double a) {
    a0 = a;
  }

  void translate(double dx, double dy) {
    x += dx; y += dy;
  }

  void invertMean() {
    x = -x; y = -y;
  }

  void rotate(double a) {
    double xt = x, yt = y;
    double cxxt = cxx, cyyt = cyy, cxyt = cxy;

    x = xt*cos(a)-yt*sin(a);
    y = xt*sin(a)+yt*cos(a);

    cxx = cxxt*cos(a)*cos(a)-2*cxyt*cos(a)*sin(a)+cyyt*sin(a)*sin(a);
    cyy = cxxt*sin(a)*sin(a)+2*cxyt*cos(a)*sin(a)+cyyt*cos(a)*cos(a);
    cxy = (cxxt-cyyt)*cos(a)*sin(a)+cxyt*(cos(a)*cos(a)-sin(a)*sin(a));
  }

  void add(Gaussian2d rhs) {
    x += rhs.x;
    y += rhs.y;

    cxx += rhs.cxx;
    cyy += rhs.cyy;
    cxy += rhs.cxy;

    checkCovariance();
  }

  void subtract(Gaussian2d rhs) {
    x -= rhs.x;
    y -= rhs.y;

    cxx += rhs.cxx;
    cyy += rhs.cyy;
    cxy += rhs.cxy;

    checkCovariance();
  }

  void multiply(Gaussian2d rhs) {
    double x0, y0, cxx0, cyy0, cxy0, cDet0;
    x0 = x;
    y0 = y;
    cxx0 = cxx;
    cyy0 = cyy;
    cxy0 = cxy;
    cDet0 = cDet;

    double ax, ay, axx, ayy, axy;
    axx = cyy0/cDet0;
    ayy = cxx0/cDet0;
    axy = -cxy0/cDet0;
    ax = axx*x0 + axy*y0;
    ay = axy*x0 + ayy*y0;

    double bx, by, bxx, byy, bxy;
    bxx = rhs.cyy/rhs.cDet;
    byy = rhs.cxx/rhs.cDet;
    bxy = -rhs.cxy/rhs.cDet;
    bx = bxx*rhs.x + bxy*rhs.y;
    by = bxy*rhs.x + byy*rhs.y;

    double invDet = (axx+bxx)*(ayy+byy)-(axy+bxy)*(axy+bxy);
    //    if (invDet < 1) invDet = 1;
    cxx = (ayy+byy)/invDet;
    cyy = (axx+bxx)/invDet;
    cxy = -(axy+bxy)/invDet;
    checkCovariance();

    x = cxx*(ax+bx) + cxy*(ay+by);
    y = cxy*(ax+bx) + cyy*(ay+by);

    double a0Add = (ax*(x-x0)+ay*(y-y0))+(bx*(x-rhs.x)+by*(y-rhs.y));
    a0Add += log(cDet) - log(cDet0) - log(rhs.cDet) - 2*log(2*PI);

    a0 += rhs.a0 + .5*a0Add;
  }

  /*
  void merge(Gaussian2d rhs, double factor = 0.5) {
    Gaussian2d product = *this;
    product.multiply(rhs);

    double aCurrent = getLogAmplitude();
    double aRhs = rhs.getLogAmplitude();
    
    const double MERGE_OFFSET = 20;
    double aProduct = product.getLogAmplitude() + MERGE_OFFSET;

//printf("merge: %g %g -> %g\n",aCurrent, aRhs, aProduct); 
    if (aCurrent > 0) aCurrent *= factor;

    if ((aProduct > aCurrent) && (aProduct > aRhs)) {
      *this = product;
      setLogAmplitude(aProduct);
    }
    else if (aRhs > aCurrent) {
      *this = rhs;
      setLogAmplitude(aRhs);
    }
    else {
      setLogAmplitude(aCurrent);
    }
  }
  */

  void limitLogAmplitude(double maxLogAmplitude) {
    if (getLogAmplitude() > maxLogAmplitude) setLogAmplitude(maxLogAmplitude);
  }

  void addLogAmplitude(double c) {
    setLogAmplitude(getLogAmplitude()+c);
  }
  
 private:
  // Representation of Gaussian:
  // exp(a0 -1/2*((v[0]-x,v[1]-y)'*inv([cxx cxy; cxy cyy])(v[0]-x,v[1]-y)
  //      -1/2*log(cDet)-log(2*pi)+1/2*a0) + 1/L^2
  double x, y;
  double cxx, cyy, cxy, cDet;
  double a0;
};

#endif
