#ifndef BallModel_h_DEFINED
#define BallModel_h_DEFINED

#include <math.h>
#include <float.h>
#include <vector>
#include <deque>
using namespace std;

#include "Gaussian2d.h"

typedef enum {
  C_PROCESS_POS_UPDATE, C_PROCESS_ANGLE_UPDATE, C_NUM_COVAR_PARAMS
} CovarianceParameter;

class BallModel {
 public:
  BallModel();
  virtual ~BallModel() {}

  void BallObservation(Gaussian2d &obsGaussian, int dFrame);
  void BallMotion(double xMove, double yMove, double aMove);
  void getBall( double &x, double &y, double &vx, double &vy, double &ex, double &evx );


  long frameNumber;

  double ballToSelf[6];

  Gaussian2d ballPosition, ballVelocity;
  int ballUncertainty;
  double covarianceParams[C_NUM_COVAR_PARAMS];
};


#endif
