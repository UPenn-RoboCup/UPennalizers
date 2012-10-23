#include "BallModel.h"
#include <math.h>
#include "Gaussian2d.h"

const double DEFAULT_RAND_POSITION_UPDATE = 30.0;
const double DEFAULT_RAND_ANGLE_UPDATE = 5*PI/180;

BallModel::BallModel() : frameNumber(0),
			   ballPosition(0, 1000),
			   ballVelocity(0, 0)
{

  for (int i = 0; i < 4; i++) {
    ballToSelf[i] = 0;
  }

  // Extra entries for ball velocity
  ballToSelf[4] = ballToSelf[5] = 0;

  ballUncertainty = 100;

  covarianceParams[C_PROCESS_POS_UPDATE] = DEFAULT_RAND_POSITION_UPDATE;
  covarianceParams[C_PROCESS_ANGLE_UPDATE] = DEFAULT_RAND_ANGLE_UPDATE;

}

void BallModel::getBall( double &x, double &y, double &vx, double &vy, double &ex, double &evx ){
    ballPosition.getMean( x, y );
    ballVelocity.getMean( vx, vy );
    ex = ballPosition.getError();
    evx = ballVelocity.getError();
}

void BallModel::BallObservation(Gaussian2d &obsGaussian, int dFrame) {


  double alphaVelocity = 0.95;  // Integrates velocity over 1/(1-alphaVelocity) frames
  double sigmaVelocity = 20.0;  // Noise in velocity update dynamics
  double sigmaPosition = 75.0; // Noise in position update dynamics

/*
  double alphaVelocity = 0.95;  // Integrates velocity over 1/(1-alphaVelocity) frames
  double sigmaVelocity = 12.0;  // Noise in velocity update dynamics
  double sigmaPosition = 45.0; // Noise in position update dynamics
*/

/*
  // Not too bad - from webots...
  double alphaVelocity = 0.95;  // Integrates velocity over 1/(1-alphaVelocity) frames
  double sigmaVelocity = 12.0;  // Noise in velocity update dynamics
  double sigmaPosition = 45.0; // Noise in position update dynamics
*/

/*
  // From Webots tests
  double alphaVelocity = 0.95;
  double sigmaVelocity = 15.0;
  double sigmaPosition = 25.0;
*/

  // Need to check cases with dFrame > 1...
  double vx, vy;
  
  // Order of calculation is important here...
  ballVelocity.getMean(vx, vy);
  vx = alphaVelocity*vx;
  vy = alphaVelocity*vy;
  ballVelocity.setMean(vx, vy);
  ballVelocity.addToCovariance(dFrame*sigmaVelocity);

  Gaussian2d velObservation(obsGaussian);
  velObservation.subtract(ballPosition);
  velObservation.getMean(vx, vy);

  //  Suppress high velocity estimates when ball reappears after being lost:
  if (dFrame != 1) {
    velObservation.setMean(0, 0);
  }
  velObservation.addToCovariance(sigmaPosition);
ballVelocity.multiply(velObservation);
  ballPosition.add(ballVelocity);
  ballPosition.addToCovariance(dFrame*sigmaPosition);
  ballPosition.multiply(obsGaussian);

  

  if (ballPosition.getLogAmplitude() < -20) {
    ballPosition = obsGaussian;

    ballVelocity.setMean(0, 0);
    ballVelocity.addToCovariance(100*sigmaVelocity);
  }

  ballPosition.setLogAmplitude(0);
  ballVelocity.setLogAmplitude(0);
  
}

void
BallModel::BallMotion(double xMove, double yMove, double aMove)
{
  double sigma = .5*sqrt(xMove*xMove + yMove*yMove /*+1E4*/); 

  ballPosition.addToCovariance(.5*sigma);
  ballPosition.translate(-xMove, -yMove);
  ballPosition.rotate(-aMove);

  ballVelocity.rotate(-aMove);
}


