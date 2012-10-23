/*
  ret = mexshm(args);

  mex -O mexshm.cc -I/usr/local/include -lrt

  Matlab MEX file to access shared memory using Boost interprocess
  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 5/10
          Jordan Brindza <brindza@seas.upenn.edu>, 3/11
*/

#include <vector>
#include <map>
#include "mex.h"

#include <boost/interprocess/managed_shared_memory.hpp>
#include <boost/interprocess/allocators/allocator.hpp>
#include <boost/interprocess/containers/vector.hpp>

using namespace boost::interprocess;

typedef double value_t;
static std::vector<managed_shared_memory *> shmHandles;

void mex_create(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  char *name = mxArrayToString(prhs[0]);
  int size = 65536;
  if (nrhs > 1)
    size = mxGetScalar(prhs[1]);

  int nshm = shmHandles.size();
  shmHandles.push_back(new managed_shared_memory(open_or_create, name, size));

  plhs[0] = mxCreateDoubleScalar(nshm);
}

void mex_delete(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int nshm = mxGetScalar(prhs[0]);
  if (shmHandles[nshm])
    delete shmHandles[nshm];
}

void mex_set(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int nshm = mxGetScalar(prhs[0]);
  const char *key = mxArrayToString(prhs[1]);
  int nvalue = mxGetNumberOfElements(prhs[2]);
  double *values = mxGetPr(prhs[2]);

  if (!shmHandles[nshm]) {
    mexErrMsgTxt("Unknown shm handle");
  }

  // Find key in shm
  std::pair<value_t*, std::size_t> ret;
  ret = shmHandles[nshm]->find<value_t>(key);
  value_t *pr = ret.first;
  int n = ret.second;
  if (pr == NULL) {
    // construct the shm key if it doesn't exist
    pr = shmHandles[nshm]->construct<value_t>(key)[nvalue]();    
  } else if (n != nvalue) {
    // if it exists but is not the correct size
    // create a new key with the correct size
    printf("WARNING: Input size %d != current block size %d. Resizing %s block.\n", nvalue, n, key);
    shmHandles[nshm]->destroy_ptr(pr);
    pr = shmHandles[nshm]->construct<value_t>(key)[nvalue]();    
  }

  for (int i = 0; i < nvalue; i++) {
    pr[i] = values[i];
  }
}

void mex_get(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int nshm = mxGetScalar(prhs[0]);
  const char *key = mxArrayToString(prhs[1]);

  // Try to find key
  std::pair<value_t*, std::size_t> ret;
  ret = shmHandles[nshm]->find<value_t>(key);
  value_t *pr = ret.first;
  int n = ret.second;
  if (pr == NULL) {
    plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
    return;
  }
  plhs[0] = mxCreateDoubleMatrix(1, n, mxREAL);
  for (int i = 0; i < n; i++) {
    mxGetPr(plhs[0])[i] = pr[i];
  }
}

void mex_size(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int nshm = mxGetScalar(prhs[0]);
  const char *key = mxArrayToString(prhs[1]);

  std::pair<value_t*, std::size_t> ret;
  ret = shmHandles[nshm]->find<value_t>(key);
  value_t *pr = ret.first;
  int n = ret.second;
  if (pr == NULL) {
    plhs[0] = mxCreateDoubleScalar(0);
  } else {
    plhs[0] = mxCreateDoubleScalar(n);
  }
}


void mex_next(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int nshm = mxGetScalar(prhs[0]);
  managed_shared_memory *shm = shmHandles[nshm];

  typedef managed_shared_memory::const_named_iterator const_named_it;
  const_named_it named_beg = shm->named_begin();
  const_named_it named_end = shm->named_end();

  if (nrhs < 2) {
    // if it is not empty return the first
    if (named_beg != named_end) { 
      plhs[0] = mxCreateString(named_beg->name());
    } else {
      plhs[0] = mxCreateString("");
    }
    return;
  }

  const char *key = mxArrayToString(prhs[1]);
  bool find = false;
  do {
    if (find) {
      plhs[0] = mxCreateString(named_beg->name());
      return;
    } else {
      const managed_shared_memory::char_type *name = named_beg->name();
      std::size_t name_len = named_beg->name_length();
      if (std::string(key) == std::string(name)) {
        find = true;
      }
    }
  } while (++named_beg != named_end);

  plhs[0] = mxCreateString("");
  return;
}

void mexExit(void)
{
  printf("Exiting mexshm.\n");
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  static bool init = false;
  static std::map<std::string, void (*)(int nlhs, mxArray *plhs[],
    int nrhs, const mxArray *prhs[])> funcMap;

  if (!init) {
    fprintf(stdout, "Starting mexshm...");

    shmHandles.reserve(1);
    shmHandles.clear();

    funcMap["new"] = mex_create;
    funcMap["delete"] = mex_delete;
    funcMap["get"] = mex_get;
    funcMap["set"] = mex_set;
    funcMap["next"] = mex_next;
    funcMap["size"] = mex_size;

    mexAtExit(mexExit);
    init = true;
  }

  if ((nrhs < 1) || (!mxIsChar(prhs[0])))
    mexErrMsgTxt("Need to input string argument");
  std::string fname(mxArrayToString(prhs[0]));

  std::map<std::string, void (*)(int nlhs, mxArray *plhs[],
    int nrhs, const mxArray *prhs[])>::iterator iFuncMap = funcMap.find(fname);

  if (iFuncMap == funcMap.end())
    mexErrMsgTxt("Unknown function argument");

  (iFuncMap->second)(nlhs, plhs, nrhs-1, prhs+1);
}
