
#pragma once

#include "Tools/Math/YaMatrix.h"

/**
 * Eigen decomposition for symmetric matrices. Adapted from JAMA.
 */
template<class V>
class YaEigenDecomposition
{
  const YaMatrix<V>& matrix;

public:
  YaMatrix<V> eigenVectors;
  YaMatrix<V> eigenValues;

  YaEigenDecomposition(const YaMatrix<V>& matrix)
    : matrix(matrix),
      eigenVectors(matrix.N, matrix.N),
      eigenValues(matrix.N, matrix.N)
  {}

  void solve()
  {
    YaMatrix<V> Q = matrix;
    YaMatrix<V> diag(matrix.N, 1);
    YaMatrix<V> e(matrix.N + 1, 1);

    householderTransform(Q, diag, e);
    qlAlgorithm(diag, e, Q);
    eigenVectors = Q;

    for(int i = 0; i < matrix.N; i++)
      eigenValues[i][i] = diag[i][0];
  }

private:
  void householderTransform(YaMatrix<V>& Q, YaMatrix<V>& d, YaMatrix<V>& e)
  {
    int n = Q.N;
    int i, j, k;

    for(j = 0; j < n; j++)
      d[j][0] = Q[n - 1][j];

    /* Householder reduction to tridiagonal form */
    for(i = n - 1; i > 0; i--)
    {
      /* Scale to avoid under/overflow */
      V scale = 0.0;
      V h = 0.0;
      for(k = 0; k < i; k++)
        scale = scale + fabs(d[k][0]);
      if(scale == 0.0)
      {
        e[i][0] = d[i - 1][0];
        for(j = 0; j < i; j++)
        {
          d[j][0] = Q[i - 1][j];
          Q[i][j] = 0.0;
          Q[j][i] = 0.0;
        }
      }
      else
      {
        /* Generate Householder vector */
        V f, g, hh;

        for(k = 0; k < i; k++)
        {
          d[k][0] /= scale;
          h += d[k][0] * d[k][0];
        }
        f = d[i - 1][0];
        g = sqrt(h);
        if(f > 0)
          g = -g;
        e[i][0] = scale * g;
        h = h - f * g;
        d[i - 1][0] = f - g;
        for(j = 0; j < i; j++)
          e[j][0] = 0.0;

        /* Apply similarity transformation to remaining columns */
        for(j = 0; j < i; j++)
        {
          f = d[j][0];
          Q[j][i] = f;
          g = e[j][0] + Q[j][j] * f;
          for(k = j + 1; k <= i - 1; k++)
          {
            g += Q[k][j] * d[k][0];
            e[k][0] += Q[k][j] * f;
          }
          e[j][0] = g;
        }
        f = 0.0;
        for(j = 0; j < i; j++)
        {
          e[j][0] /= h;
          f += e[j][0] * d[j][0];
        }
        hh = f / (h + h);
        for(j = 0; j < i; j++)
        {
          e[j][0] -= hh * d[j][0];
        }
        for(j = 0; j < i; j++)
        {
          f = d[j][0];
          g = e[j][0];
          for(k = j; k <= i - 1; k++)
          {
            Q[k][j] -= (f * e[k][0] + g * d[k][0]);
          }
          d[j][0] = Q[i - 1][j];
          Q[i][j] = 0.0;
        }
      }
      d[i][0] = h;
    }

    /* Accumulate transformations */
    for(i = 0; i < n - 1; i++)
    {
      V h;
      Q[n - 1][i] = Q[i][i];
      Q[i][i] = 1.0;
      h = d[i + 1][0];
      if(h != 0.0)
      {
        for(k = 0; k <= i; k++)
          d[k][0] = Q[k][i + 1] / h;
        for(j = 0; j <= i; j++)
        {
          V g = 0.0;
          for(k = 0; k <= i; k++)
            g += Q[k][i + 1] * Q[k][j];
          for(k = 0; k <= i; k++)
            Q[k][j] -= g * d[k][0];
        }
      }
      for(k = 0; k <= i; k++)
        Q[k][i + 1] = 0.0;
    }
    for(j = 0; j < n; j++)
    {
      d[j][0] = Q[n - 1][j];
      Q[n - 1][j] = 0.0;
    }
    Q[n - 1][n - 1] = 1.0;
    e[0][0] = 0.0;
  }

  void qlAlgorithm(YaMatrix<V>& d, YaMatrix<V>& e, YaMatrix<V>& Q)
  {
    int n = Q.N;
    int i, k, l, m;
    V f = 0.0;
    V tst1 = 0.0;
    V eps = (V)2.22e-16; /* Math.pow(2.0,-52.0);  == 2.22e-16 */

    /* shift input e */
    for(i = 1; i < n; i++)
      e[i - 1][0] = e[i][0];
    e[n - 1][0] = 0.0; /* never changed again */

    for(l = 0; l < n; l++)
    {
      /* Find small subdiagonal element */
      if(tst1 < fabs(d[l][0]) + fabs(e[l][0]))
        tst1 = fabs(d[l][0]) + fabs(e[l][0]);
      m = l;
      while(m < n)
      {
        if(fabs(e[m][0]) <= eps * tst1)
          break;
        m++;
      }

      /* If m == l, d[l] is an eigenvalue, */
      /* otherwise, iterate. */
      if(m > l)
      {
        int iter = 0;
        do   /* while (fabs(e[l]) > eps*tst1); */
        {
          V dl1, h;
          V g = d[l][0];
          V p = (d[l + 1][0] - g) / (2.0f * e[l][0]);
          V r = myhypot(p, 1.);

          iter = iter + 1;  /* Could check iteration count here */

          /* Compute implicit shift */
          if(p < 0)
            r = -r;
          d[l][0] = e[l][0] / (p + r);
          d[l + 1][0] = e[l][0] * (p + r);
          dl1 = d[l + 1][0];
          h = g - d[l][0];
          for(i = l + 2; i < n; i++)
            d[i][0] -= h;
          f = f + h;

          /* Implicit QL transformation. */
          p = d[m][0];
          {
            V c = 1.0;
            V c2 = c;
            V c3 = c;
            V el1 = e[l + 1][0];
            V s = 0.0;
            V s2 = 0.0;
            for(i = m - 1; i >= l; i--)
            {
              c3 = c2;
              c2 = c;
              s2 = s;
              g = c * e[i][0];
              h = c * p;
              r = myhypot(p, e[i][0]);
              e[i + 1][0] = s * r;
              s = e[i][0] / r;
              c = p / r;
              p = c * d[i][0] - s * g;
              d[i + 1][0] = h + s * (c * g + s * d[i][0]);

              /* Accumulate transformation. */

              for(k = 0; k < n; k++)
              {
                h = Q[k][i + 1];
                Q[k][i + 1] = s * Q[k][i] + c * h;
                Q[k][i] = c * Q[k][i] - s * h;
              }
            }
            p = -s * s2 * c3 * el1 * e[l][0] / dl1;
            e[l][0] = s * p;
            d[l][0] = c * p;
          }

          /* Check for convergence. */
        }
        while(fabs(e[l][0]) > eps * tst1);
      }
      d[l][0] = d[l][0] + f;
      e[l][0] = 0.0;
    }

    /* Sort eigenvalues and corresponding vectors. */
    {
      int j;
      V p;
      for(i = 0; i < n - 1; i++)
      {
        k = i;
        p = d[i][0];
        for(j = i + 1; j < n; j++)
        {
          if(d[j][0] < p)
          {
            k = j;
            p = d[j][0];
          }
        }
        if(k != i)
        {
          d[k][0] = d[i][0];
          d[i][0] = p;
          for(j = 0; j < n; j++)
          {
            p = Q[j][i];
            Q[j][i] = Q[j][k];
            Q[j][k] = p;
          }
        }
      }
    }
  }

  /** sqrt(a^2 + b^2) numerically stable. */
  V myhypot(V a, V b)
  {
    V r = 0;
    if(fabs(a) > fabs(b))
    {
      r = b / a;
      r = fabs(a) * sqrt(1 + r * r);
    }
    else if(b != 0)
    {
      r = a / b;
      r = fabs(b) * sqrt(1 + r * r);
    }
    return r;
  }
};
