/*
  astar_nonholonomic16.cc
  [cost_to_go] = dijkstra_nonholonomic(A, xya_goal, xya_start);
  where positive costs are given in matrix A with 16 different orientations.
  
  Compile: mex -O astar_nonholonomic16.cc
  Written by Daniel D. Lee (ddlee@seas.upenn.edu), 9/2007
*/

#include <math.h>
#include <set>
#include "mex.h"

#define STOP_FACTOR 1.1

using namespace std;

typedef pair<double, int> CostNodePair; // (cost, node)

typedef struct {
  int ioffset;
  int joffset;
  double distance;
} NeighborStruct;
NeighborStruct neighbors[] = {
  {1,0,1.0}, {2,1,sqrt(5)}, {1,1,sqrt(2)}, {1,2,sqrt(5)},
  {0,1,1.0}, {-1,2,sqrt(5)}, {-1,1,sqrt(2)}, {-2,1,sqrt(5)},
  {-1,0,1.0}, {-2,-1,sqrt(5)}, {-1,-1,sqrt(2)}, {-1,-2,sqrt(5)},
  {0,-1,1.0}, {1,-2,sqrt(5)}, {1,-1,sqrt(2)}, {2,-1,sqrt(5)},
};
int nNeighbors = sizeof(neighbors)/sizeof(NeighborStruct);

double rTurn = (nNeighbors/2)+1;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs < 3) {
    mexErrMsgTxt("Need at least three input arguments");
  }

  double *A = mxGetPr(prhs[0]);
  int m = mxGetM(prhs[0]);
  int n = mxGetN(prhs[0]);

  if (mxGetM(prhs[1])*mxGetN(prhs[1]) != 3) {
    mexErrMsgTxt("Goal should be (xgoal, ygoal, agoal)");
  }
  double *prGoal = mxGetPr(prhs[1]);

  if (mxGetM(prhs[2])*mxGetN(prhs[2]) != 3) {
    mexErrMsgTxt("Start should be (xstart, ystart, astart)");
  }
  double *prStart = mxGetPr(prhs[2]);

  int iGoal = round(prGoal[0]-1); // 0-indexing
  if (iGoal < 0) iGoal = 0;
  if (iGoal > m-1) iGoal = m-1;
  int jGoal = round(prGoal[1]-1);
  if (jGoal < 0) jGoal = 0;
  if (jGoal > n-1) jGoal = n-1;
  int aGoal = round(nNeighbors/(2*M_PI)*prGoal[2]);
  aGoal = aGoal % nNeighbors;
  if (aGoal < 0) aGoal += nNeighbors;
  int indGoal = iGoal + m*jGoal + m*n*aGoal; // linear index

  int iStart = round(prStart[0]-1);
  if (iStart < 0) iStart = 0;
  if (iStart > m-1) iStart = m-1;
  int jStart = round(prStart[1]-1);
  if (jStart < 0) jStart = 0;
  if (jStart > n-1) jStart = n-1;
  int aStart = round(nNeighbors/(2*M_PI)*prStart[2]);
  aStart = aStart % nNeighbors;
  if (aStart < 0) aStart += nNeighbors;
  int indStart = iStart + m*jStart + m*n*aStart; // linear index

  // Cost to go values
  int dims[3];
  dims[0] = m;
  dims[1] = n;
  dims[2] = nNeighbors;
  plhs[0] = mxCreateNumericArray(3,dims,mxDOUBLE_CLASS,mxREAL);
  double *D = mxGetPr(plhs[0]);
  for (int i = 0; i < nNeighbors*m*n; i++) D[i] = INFINITY;
  D[indGoal] = 0;

  // Priority queue implementation as STL set
  set<CostNodePair> Q; // Sorted set of (cost to go, node)
  Q.insert(CostNodePair(0, indGoal));

int nNode = 0;
  while (!Q.empty()) {
nNode++;
    // Fetch closest node in queue
    CostNodePair top = *Q.begin();
    Q.erase(Q.begin());
    double f0 = top.first;
    int ind0 = top.second;
    double c0 = D[ind0];

    // Short circuit computation if path to start has been found:
    if (f0 > STOP_FACTOR*D[indStart]) break;

    // Array subscripts of node:
    int a0 = ind0 / (m*n);
    int ij0 = ind0 - a0*m*n;
    int j0 = ij0 / m;
    int i0 = ij0 % m;
    // Iterate over neighbor nodes:
    for (int ashift = -1; ashift <= +1; ashift++) {
      int a1 = (a0+nNeighbors+ashift) % nNeighbors; // Non-negative heading index

      int ioffset = neighbors[a1].ioffset;
      int joffset = neighbors[a1].joffset;

      int i1 = i0 - ioffset;
      if ((i1 < 0) || (i1 >= m)) continue;
      int j1 = j0 - joffset;
      if ((j1 < 0) || (j1 >= n)) continue;

      double cost = A[ij0];
      int koffset = floor(neighbors[a1].distance);
      for (int k = 1; k < koffset; k++) {
	int ik = i0 - k*ioffset/koffset;
	int jk = j0 - k*joffset/koffset;
	cost += A[m*jk+ik];
      }
      cost /= koffset;

      double c1 = c0 + cost*neighbors[a1].distance;
      // Heuristic cost to start:
      double h1 = sqrt((iStart-i1)*(iStart-i1)+(jStart-j1)*(jStart-j1));
      // Estimated total cost:
      double f1 = c1 + h1;

      int ind1 = m*j1 + i1 + m*n*a1;
      if (c1 < D[ind1]) {
	if (!isinf(D[ind1])) {
	  Q.erase(CostNodePair(D[ind1]+h1,ind1));
	}
	D[ind1] = c1;
	Q.insert(CostNodePair(f1, ind1));
      }
      
    }
  }

printf("Astar: nodes = %d, queue = %d\n", nNode,Q.size());
  
}
