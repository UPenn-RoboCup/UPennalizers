/*
  dijkstra_matrix.cc
  [cost_to_go] = dijkstra_matrix(A, i_goal, j_goal);
  where positive costs are given in matrix A with 8-connected neighbors,
  and (i_goal, j_goal) is the goal node.
  
  Compile: mex -O dijkstra_matrix.cc
  Written by Daniel D. Lee (ddlee@seas.upenn.edu), 4/2007
*/

#include <math.h>
#include <set>
#include "mex.h"
 
using namespace std;

typedef pair<double, int> CostNodePair; // (cost, node)

typedef struct {
  int ioffset;
  int joffset;
  double distance;
} NeighborStruct;
NeighborStruct neighbors[] = {
  {-1,0, 1.0}, {1,0, 1.0}, {0,-1, 1.0}, {0,1, 1.0}, // 4-connected
  {-1,-1, sqrt(2)}, {1,-1, sqrt(2)}, {-1,1, sqrt(2)}, {1,1, sqrt(2)} // 8-connected
};
int nNeighbors = sizeof(neighbors)/sizeof(NeighborStruct);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs < 1) {
    mexErrMsgTxt("Need at least one input arguments");
  }

  double *A = mxGetPr(prhs[0]);
  int m = mxGetM(prhs[0]);
  int n = mxGetN(prhs[0]);

  int iGoal = 0;
  int jGoal = 0;
  if (nrhs >= 3) {
    iGoal = mxGetScalar(prhs[1])-1; // 0-indexed nodes
    if (iGoal < 0) iGoal = 0;
    if (iGoal >= m-1) iGoal = m-1;
    jGoal = mxGetScalar(prhs[2])-1; // 0-indexed nodes
    if (jGoal < 0) iGoal = 0;
    if (jGoal >= n-1) iGoal = n-1;
  }
  int indGoal = iGoal+m*jGoal; // linear index

  // Cost to go values
  plhs[0] = mxCreateDoubleMatrix(m,n,mxREAL);
  double *D = mxGetPr(plhs[0]);
  for (int i = 0; i < m*n; i++) D[i] = INFINITY;
  D[indGoal] = 0;

  // Priority queue implementation as STL set
  set<CostNodePair> Q; // Sorted set of (cost to go, node)
  Q.insert(CostNodePair(0, indGoal));

  while (!Q.empty()) {
    // Fetch closest node in queue
    CostNodePair top = *Q.begin();
    Q.erase(Q.begin());
    double c0 = top.first;
    int ind0 = top.second;

    // Array subscripts of node:
    int i0 = ind0 % m;
    int j0 = ind0 / m;
    // Iterate over neighbor nodes:
    for (int k = 0; k < nNeighbors; k++) {
      int i1 = i0 + neighbors[k].ioffset;
      if ((i1 < 0) || (i1 >= m)) continue;
      int j1 = j0 + neighbors[k].joffset;
      if ((j1 < 0) || (j1 >= n)) continue;
      int ind1 = m*j1+i1;

      double c1 = c0 + 0.5*(A[ind0]+A[ind1])*neighbors[k].distance;
      if (c1 < D[ind1]) {
	if (!isinf(D[ind1])) {
	  Q.erase(Q.find(CostNodePair(D[ind1],ind1)));
	}
	D[ind1] = c1;
	Q.insert(CostNodePair(D[ind1], ind1));
      }
    }
  }

}
