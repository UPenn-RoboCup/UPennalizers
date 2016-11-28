/*
  dijkstra_graph.cc
  [cost_to_go, next_index] = dijkstra_graph(A, goal_index)
  where connected edge costs i->j are given as positive entries
  in the sparse adjacency matrix A(i,j).
  
  dist is the cost to go to the goal node
  next_index containts the next index to traverse

  Compile: mex -O dijkstra_graph.cc
  Written by Daniel D. Lee (ddlee@seas.upenn.edu), 4/2007
*/

#include <math.h>
#include <vector>
#include <set>
#include <utility>
#include "mex.h"

using namespace std;

typedef pair<double,int> di;  // (cost, from node)
typedef vector<di> vdi; // edge list for a single to node
typedef vector<vdi> vvdi; // vector of edge lists to all nodes

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs < 1) {
    mexErrMsgTxt("Need at least one input arguments");
  }

  const mxArray *A = prhs[0];
  int n = mxGetN(A);
  if (n != mxGetM(A)) {
    mexErrMsgTxt("Adjacency matrix must be square");
  }

  int index_goal = 0;
  if (nrhs >= 2) {
    index_goal = mxGetScalar(prhs[1])-1; // 0-indexed nodes
  }

  // Graph G is given by directed edges to node i
  // from node G[i][j].second with cost G[i][j].first
  vvdi G(n);

  double *apr = mxGetPr(A);
  int *air = mxGetIr(A);
  int *ajc = mxGetJc(A);

  // Get adjacency structure and costs from sparse matrix A
  for (int jc = 0; jc < n; jc++) {
    int nr = ajc[jc+1]-ajc[jc];
    G[jc].reserve(nr);
    G[jc].clear();
    for (int i = ajc[jc]; i < ajc[jc+1]; i++) {
      if (air[i] != jc) {  // Ignore self connections
	G[jc].push_back(di(apr[i],air[i]));  // Edge from air[i] to jc
      }
    }
  }

  /*
  // Print out graph structure
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < G[i].size(); j++) {
      mexPrintf("%d -> %d = %g\n",G[i][j].second,i,
		G[i][j].first);
    }
  }
  */

  // Shortest cost values
  plhs[0] = mxCreateDoubleMatrix(n,1,mxREAL);
  double *D = mxGetPr(plhs[0]);
  for (int i = 0; i < n; i++) D[i] = INFINITY;
  D[index_goal] = 0;

  // Index to next node in path
  plhs[1] = mxCreateDoubleMatrix(n,1,mxREAL);
  double *P = mxGetPr(plhs[1]);
  P[index_goal] = index_goal+1;

  // Priority queue implementation as STL set
  set<di> Q;  // Sorted set of (cost to go, node)
  Q.insert(di(0,index_goal));
  while (!Q.empty()) {
    // Fetch closest node
    di top = *Q.begin();
    Q.erase(Q.begin());
    double d = top.first;
    int v = top.second;

    // Iterate over nodes going to v:
    for (vdi::const_iterator iv = G[v].begin(); iv != G[v].end(); iv++) {
      double cost = iv->first;
      int v2 = iv->second;
      if (D[v2] > D[v] + cost) {
	if (!isinf(D[v2])) {
	  Q.erase(Q.find(di(D[v2],v2)));
	}
	D[v2] = D[v] + cost;
	P[v2] = v+1;
	Q.insert(di(D[v2], v2));
      }
    }
  }

}
