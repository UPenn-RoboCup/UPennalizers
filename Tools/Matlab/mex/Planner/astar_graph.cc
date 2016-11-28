/*
  astar_graph.cc
  path = astar_graph(A, xy, start_index, goal_index)
  where connected edge costs are given as positive entries
  in the sparse adjacency matrix A, with nodes located at xy(i,:),
  i.e. same as in Matlab function gplot(A, xy)

  Costs need to be bounded by:
  A(i,j) >= norm(xy(j,:)-xy(i,:))

  Compile: mex -O astar_graph.cc
  Written by Daniel D. Lee (ddlee@seas.upenn.edu), 6/2007
*/

#include <math.h>
#include <algorithm>
#include <vector>
#include "mex.h"

using namespace std;

typedef pair<double,int> di;  // (cost, target node)
typedef vector<di> vdi; // edge list for a single source node
typedef vector<vdi> vvdi; // vector of edge lists from all nodes

// AStar search class:
class AStarSearch {
public: // data
  enum
    {
      SEARCH_UNDEFINED,
      SEARCH_SEARCHING,
      SEARCH_SUCCESS,
      SEARCH_FAILED
    };

  enum
    {
      NODE_OPEN,
      NODE_CLOSED
    };

  class Node {
  public:
    int index;
    int state;
    double g; // cost to this node
    double h; // heuristic estimate of distance to goal
    double f; // sum of cumulative cost and heuristic
    Node *parent;

    Node(int index_=0) :
      index(index_),
      state(NODE_OPEN),
      g(0), h(0), f(0),
      parent(0)
    { }
  };

  // Sorting values in priority queue
  class HeapCompare_f {
  public:
    bool operator() (const Node *a, const Node *b) const {
      return a->f > b->f;
    }
  };

 public: // methods

  // constructor just initialises private data
  AStarSearch(vvdi *G_, double *x_, double *y_) :
    ng((*G_).size()),
    G(G_),
    node(ng),
    start_index(0),
    goal_index(0),
    x(x_),
    y(y_),
    openList(),
    solutionList(),
    searchState(SEARCH_UNDEFINED)
  { }

  ~AStarSearch() { FreeNodes(); }

  double DistanceEstimate(int i) {
    double dx = x[goal_index] - x[i];
    double dy = y[goal_index] - y[i];
  
    return sqrt(dx*dx + dy*dy);
  }

  void SetStartAndGoal(int istart, int igoal) {
    start_index = istart;
    goal_index = igoal;

    FreeNodes();

    node[start_index] = new Node(start_index);
    node[start_index]->g = 0;
    node[start_index]->h = DistanceEstimate(start_index);
    node[start_index]->f = node[start_index]->g + node[start_index]->h;
    node[start_index]->parent = 0;
    node[start_index]->state = NODE_OPEN;

    openList.push_back(node[start_index]);
    push_heap(openList.begin(), openList.end(), HeapCompare_f());

    searchState = SEARCH_SEARCHING;
  }

  // Advances search one step 
  unsigned int SearchStep() {
    if (searchState != SEARCH_SEARCHING) {
      return searchState;
    }

    if (openList.empty()) {
      searchState = SEARCH_FAILED;
      return searchState;
    }

    // Pop the best node (the one with the lowest f) 
    Node *n = openList.front(); // get pointer to the node
    n->state = NODE_CLOSED;
    pop_heap(openList.begin(), openList.end(), HeapCompare_f());
    openList.pop_back();

    //    mexPrintf("SearchStep: node(%d,%d)->f=%g\n",n->x,n->y,n->f);
      
    // Check for the goal
    if (n->index == goal_index) {
      searchState = SEARCH_SUCCESS;
      return searchState;
    }

    // Current node popped from open list is not goal
    for (int j = 0; j < (*G)[n->index].size(); j++) {
      int target_index = (*G)[n->index][j].second;
      double gnew = n->g + (*G)[n->index][j].first;

      if (!node[target_index]) {
	// Create new open node
	node[target_index] = new Node(target_index);
	node[target_index]->g = gnew;
	node[target_index]->h = DistanceEstimate(target_index);
	node[target_index]->f = node[target_index]->g + node[target_index]->h;
	node[target_index]->parent = n;
	node[target_index]->state = NODE_OPEN;

	openList.push_back(node[target_index]);
	push_heap(openList.begin(), openList.end(), HeapCompare_f());
      }
      else if (gnew < node[target_index]->g) {
	node[target_index]->g = gnew;
	node[target_index]->f = node[target_index]->g + node[target_index]->h;
	node[target_index]->parent = n;
	if (node[target_index]->state == NODE_CLOSED) {
	  node[target_index]->state = NODE_OPEN;
	  openList.push_back(node[target_index]);
	  push_heap(openList.begin(), openList.end(), HeapCompare_f());
	}
	else {
	  // Node changed on open list: need to resort open list
	  make_heap(openList.begin(), openList.end(), HeapCompare_f());
	}
      }
    }

    searchState = SEARCH_SEARCHING;
    return searchState;
  }

  int GetSolutionLength() {
    solutionList.clear();
    
    Node *n = node[goal_index];
    while (n != NULL) {
      solutionList.push_back(n);
      n = n->parent;
    }

    return solutionList.size();
  }

  int GetSolutionNode(int &index) {
    if (solutionList.empty()) {
      return 0;
    }
    Node *n = solutionList.back();
    solutionList.pop_back();
    index = n->index;
    return 1;
  }

  void FreeNodes() {
    searchState = SEARCH_UNDEFINED;
    for (int i = 0; i < ng; i++) {
      Node *n = node[i];
      if (n != NULL) {
	delete n;
	node[i] = NULL;
      }
    }
    openList.clear();
    solutionList.clear();
    //    node.clear();
  }

 private: // data

  int ng;
  vvdi *G;
  double *x, *y;
  
  int start_index, goal_index;
  
  // linear indexed map nodes
  vector<Node *> node;
  
  // vector used as priority queue heap
  vector<Node *> openList;

  // vector to store solution path
  vector<Node *> solutionList;

  // State
  unsigned int searchState;
};

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs < 2) {
    mexErrMsgTxt("Need at least three input arguments");
  }

  const mxArray *A = prhs[0];
  int n = mxGetN(A);
  if (mxGetM(A) != n) {
    mexErrMsgTxt("Adjacency matrix must be square");
  }

  if ((mxGetM(prhs[1]) != n) || (mxGetN(prhs[1]) != 2)) {
    mexErrMsgTxt("Coordinate matrix must be n x 2");
  }
  double *pxy = mxGetPr(prhs[1]);

  int nwaypoints = mxGetM(prhs[2])*mxGetN(prhs[2]);
  double *waypoints = mxGetPr(prhs[2]);

  // Graph G is given by directed edges from node i
  // to node G[i][j].second with cost G[i][j].first
  vvdi G(n);
  for (int i = 0; i < n; i++) {
    G[i].clear();
  }

  double *apr = mxGetPr(A);
  int *air = mxGetIr(A);
  int *ajc = mxGetJc(A);

  // Get adjacency structure and costs from sparse matrix A
  for (int jc = 0; jc < n; jc++) {
    int nr = ajc[jc+1]-ajc[jc];
    for (int i = ajc[jc]; i < ajc[jc+1]; i++) {
      if (air[i] != jc) {  // Ignore self connections
	G[air[i]].push_back(di(apr[i],jc)); // Edge from air[i] to jc
      }
    }
  }

  // Print out graph structure
  /*
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < G[i].size(); j++) {
      mexPrintf("%d -> %d = %g\n",i,G[i][j].second,
		G[i][j].first);
    }
  }
  */


  AStarSearch astarsearch(&G, pxy, pxy+n);
  vector<int> path;
  path.push_back(waypoints[0]-1); // 0-indexing

  for (int iwaypoint = 0; iwaypoint < nwaypoints-1; iwaypoint++) {
    int istart = waypoints[iwaypoint]-1; // 0-indexing
    int igoal = waypoints[iwaypoint+1]-1; // 0-indexing

    astarsearch.SetStartAndGoal(istart, igoal);
    int searchState, nSearch = 0;
    do {
      searchState = astarsearch.SearchStep();
      if (++nSearch > n*n) break;
    } while (searchState == AStarSearch::SEARCH_SEARCHING);

    if (searchState != AStarSearch::SEARCH_SUCCESS) {
      mexErrMsgTxt("Search terminated. Did not find goal state.");
    }

    int npath = astarsearch.GetSolutionLength();
    for (int ipath = 0; ipath < npath; ipath++) {
      int index;
      if (astarsearch.GetSolutionNode(index) && (ipath > 0)) {
	path.push_back(index);
      }
    }
  }

  plhs[0] = mxCreateDoubleMatrix(path.size(), 1, mxREAL);
  double *pathpr = mxGetPr(plhs[0]);
  for (int i = 0; i < path.size(); i++) {
    pathpr[i] = path[i]+1; // Convert to 1-indexing
  }

}
