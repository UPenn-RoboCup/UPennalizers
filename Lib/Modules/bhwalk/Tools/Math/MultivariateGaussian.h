
#pragma once

#include "Tools/Math/YaMatrix.h"
#include "Tools/Math/Common.h"
#include <cmath>
#include <cstdlib>
#include <ctime>

template<class T>
class MultivariateGaussian
{
  YaMatrix<T>& mean;
  YaMatrix<T>& covariance;
  YaMatrix<T> choleskyDecomposition;
public:
  MultivariateGaussian(YaMatrix<T>& mean, YaMatrix<T>& covariance)
    : mean(mean),
      covariance(covariance),
      choleskyDecomposition(covariance.choleskyDecomposition())
  {
    static bool seedInitialized = false;
    if(!seedInitialized)
    {
      srand((unsigned)time(0));
      seedInitialized = true;
    }
  }

  void setCovariance(YaMatrix<T>& covariance)
  {
    this->covariance = covariance;
    choleskyDecomposition = covariance.choleskyDecomposition();
  }

  void setMean(YaMatrix<T>& mean)
  {
    this->mean = mean;
  }

  /**
   * Samples a vector from a multivariate gaussian distribution.
   */
  YaMatrix<T> sample() const
  {
    YaMatrix<T> standardNormalDistributedVector(mean.M, 1);
    for(int i = 0; i < mean.M; i++)
      standardNormalDistributedVector[i][0] = sampleNormalDistribution();
    return mean + choleskyDecomposition * standardNormalDistributedVector;
  }

private:
  T uniform() const
  {
    return (T(rand()) / T(RAND_MAX));
  }

  /**
   * Box–Muller transform.
   * Draws a sample from a normal distribution with zero mean and variance 1.
   * @see http://en.wikipedia.org/wiki/Box-Muller_transform
   */
  T sampleNormalDistribution() const
  {
    return sqrt(T(-2) * log(uniform())) * cos(T(2) * T(pi) * uniform());
  }
};
