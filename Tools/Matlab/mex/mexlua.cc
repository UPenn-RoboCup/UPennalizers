
#include <lua.hpp>
#include <iostream>
#include <map>
#include <string>
#include <cstring>
#include <sstream>
#include <vector>
#include <deque>
#include "mex.h"

using namespace std;

static lua_State *L;

void mexExit(void) {
  fprintf(stdout, "Existing mex lua \n");
  fflush(stdout);
}

void mex_lua_run(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  if ((nrhs < 1) || !mxIsChar(prhs[0]))
    mexErrMsgTxt("Need to input string");
  string luastring(mxArrayToString(prhs[0]));

  if (luaL_loadstring(L, luastring.c_str()) || lua_pcall(L, 0, 0, 0)) {
    mexPrintf("%s\n", lua_tostring(L, -1));
    mexErrMsgTxt("failure");
  }

}

deque<string> &split(const string &str, char delim, deque<string> &elems) {
  stringstream ss(str);
  string item;
  while (getline(ss, item, delim)) {
    elems.push_back(item);
  }
}

deque<string> split(const string &str, char delim) {
  deque<string> elems;
  split(str, delim, elems);
  return elems;
}

mxArray * mex_lua_getfield_table(lua_State *L, int index, int depth) {
    /* iterate first time to get num of first level keys */
    int nfields = 0;
    lua_pushnil(L);
    while (lua_next(L, index)) {
      nfields ++;
      lua_pop(L, 1);
    }
    const char **field_name = (const char **)mxCalloc(nfields, sizeof(const char *));
    /* iterate table again to get keys */
    nfields = 0;
    lua_pushnil(L);
    const char * key_str;
    size_t key_len = 0;
    while (lua_next(L, index)) {
      key_str = lua_tolstring(L, -2, &key_len);
      field_name[nfields] = (const char*)mxCalloc(key_len + 1, sizeof(char));
      memcpy((char*)field_name[nfields++], key_str, key_len * sizeof(char));
//      mexPrintf("key :%s %d\n", key_str, key_len);
      lua_pop(L, 1);
    }
    mxArray *ret = mxCreateStructMatrix(1, 1, nfields, (const char**)field_name);

    /* iterate table again to construct structure */
    nfields = 0;
    lua_pushnil(L);
    while (lua_next(L, index)) {
      int ifield = mxGetFieldNumber(ret, field_name[nfields++]);
//      mexPrintf(" :%s\n", lua_typename(L, lua_type(L, -1)));
      if (depth < 2) 
        mxSetFieldByNumber(ret, 0, ifield, mex_lua_getfield_table(L, lua_gettop(L), depth + 1));
      else
        mxSetFieldByNumber(ret, 0, ifield, mxCreateDoubleScalar(0));
      lua_pop(L, 1);
    }

    for (int i = 0; i < nfields; i++)
      mxFree((void *)field_name[i]);
    mxFree(field_name); 
    return ret;
}

void mex_lua_getfield(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  if ((nrhs < 1) || !mxIsChar(prhs[0]))
    mexErrMsgTxt("Need to input string");
  string fields(mxArrayToString(prhs[0]));

  // split fields string with .
  deque<string> tokens = split(fields, '.');

  int token_idx = 0;
  while (tokens.size() > 0) {
    if (!token_idx) {
      // first token shoule be global variable
      lua_getglobal(L, tokens.front().c_str());
    } else {
      lua_getfield(L, -1, tokens.front().c_str());
    }
    token_idx ++;
    if (lua_type(L, -1) == LUA_TNIL) {
      lua_pop(L, token_idx);
      mexPrintf("field %s not exist\n", tokens.front().c_str());
      mexErrMsgTxt("failure");
    }
    tokens.pop_front();
  }

  int field_type = lua_type(L, -1);
  if (field_type == LUA_TBOOLEAN)
    plhs[0] = mxCreateLogicalScalar(lua_toboolean(L, -1));
  else if (field_type == LUA_TNUMBER)
    plhs[0] = mxCreateDoubleScalar(lua_tonumber(L, -1));
  else if (field_type == LUA_TSTRING) {
    const char **str_array = (const char **)mxMalloc(sizeof(const char *)); 
    str_array[0] = lua_tostring(L, -1);
    plhs[0] = mxCreateCharMatrixFromStrings(1, str_array);
    mxFree((void *)str_array);
  } else if (field_type == LUA_TTABLE) {
    plhs[0] = mex_lua_getfield_table(L, lua_gettop(L), 1);
  } else
    plhs[0] = mxCreateDoubleScalar(0);

  lua_pop(L, token_idx);

}

void mex_lua_addcpath(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
//  mexPrintf("add cpath\n");
  if ((nrhs < 1) || !mxIsChar(prhs[0]))
    mexErrMsgTxt("Need to input new cpath string");
  string add_cpath(mxArrayToString(prhs[0]));

  lua_getglobal(L, "package");
  lua_getfield(L, -1, "cpath");
  string current_cpath(lua_tostring(L, -1));
  string new_cpath = add_cpath + "/?.so;" + current_cpath;
  lua_pop(L, 1);
  lua_pushstring(L, new_cpath.c_str());
  lua_setfield(L, -2, "cpath");
  lua_pop(L, 1);
 
}

void mex_lua_getcpath(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
//  mexPrintf("get cpath\n");
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "cpath");
  string current_cpath(lua_tostring(L, -1));
  lua_pop(L, 2);

  plhs[0] = mxCreateString(current_cpath.c_str());
}

void mex_lua_addpath(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
//  mexPrintf("add path\n");
  if ((nrhs < 1) || !mxIsChar(prhs[0]))
    mexErrMsgTxt("Need to input new path string");
  string add_path(mxArrayToString(prhs[0]));

  lua_getglobal(L, "package");
  lua_getfield(L, -1, "path");
  string current_path(lua_tostring(L, -1));
  string new_path = add_path + "/?.lua;" + current_path;
  lua_pop(L, 1);
  lua_pushstring(L, new_path.c_str());
  lua_setfield(L, -2, "path");
  lua_pop(L, 1);
 
}

void mex_lua_getpath(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
//  mexPrintf("get path\n");
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "path");
  string current_path(lua_tostring(L, -1));
  lua_pop(L, 2);

  plhs[0] = mxCreateString(current_path.c_str());
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 

  static bool init = false;
  static map<string, void(*)(int nlhs, mxArray *plhs[], 
            int nrhs, const mxArray *prhs[])> funcMap;

  if (!init) {
    fprintf(stdout, "Starting lua mex...\n");
    funcMap["add_path"] = mex_lua_addpath;
    funcMap["get_path"] = mex_lua_getpath;
    funcMap["add_cpath"] = mex_lua_addcpath;
    funcMap["get_cpath"] = mex_lua_getcpath;
    funcMap["run"] = mex_lua_run;
    funcMap["get_field"] = mex_lua_getfield;

    L = luaL_newstate();
    luaL_openlibs(L);

    mexAtExit(mexExit);
    init = true;
  }

  if ((nrhs < 1) || !mxIsChar(prhs[0]))
    mexErrMsgTxt("Need to input string command");
  string cmd_name(mxArrayToString(prhs[0]));

  map<string, void(*)(int nlhs, mxArray *plhs[], int nrhs, 
      const mxArray *prhs[])>::iterator iFuncMap = funcMap.find(cmd_name);
  if (iFuncMap == funcMap.end())
    mexErrMsgTxt("Unknown command");

  (iFuncMap->second)(nlhs, plhs, nrhs-1, prhs+1);

}

