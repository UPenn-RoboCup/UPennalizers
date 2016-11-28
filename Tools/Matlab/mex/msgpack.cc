/* 
 * MessagePack for Matlab
 *
 * Copyright [2013] [ Yida Zhang <yida@seas.upenn.edu> ]
 *              University of Pennsylvania
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * */

#include <unistd.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <msgpack.h>

#include "mex.h"
#include "matrix.h"

mxArray* mex_unpack_boolean(msgpack_object obj);
mxArray* mex_unpack_positive_integer(msgpack_object obj);
mxArray* mex_unpack_negative_integer(msgpack_object obj);
mxArray* mex_unpack_double(msgpack_object obj);
mxArray* mex_unpack_raw(msgpack_object obj);
mxArray* mex_unpack_nil(msgpack_object obj);
mxArray* mex_unpack_map(msgpack_object obj);
mxArray* mex_unpack_array(msgpack_object obj);

typedef struct mxArrayRes mxArrayRes;
struct mxArrayRes {
  mxArray * res;
  mxArrayRes * next;
};

void (*PackMap[17]) (msgpack_packer *pk, int nrhs, const mxArray *prhs);
mxArray* (*unPackMap[8]) (msgpack_object obj);

void mexExit(void) {
  fprintf(stdout, "Existing Mex Msgpack \n");
  fflush(stdout);
}

mxArrayRes * mxArrayRes_new(mxArrayRes * head, mxArray* res) {
  mxArrayRes * new_res = (mxArrayRes *)mxCalloc(1, sizeof(mxArrayRes));
  new_res->res = res;
  new_res->next = head;
  return new_res;
}

void mxArrayRes_free(mxArrayRes * head) {
  mxArrayRes * cur_ptr = head;
  mxArrayRes * ptr = head; 
  while (cur_ptr != NULL) {
    ptr = ptr->next;
    mxFree(cur_ptr);
    cur_ptr = ptr;
  }
}

mxArray* mex_unpack_boolean(msgpack_object obj) {
  return mxCreateLogicalScalar(obj.via.boolean);
}

mxArray* mex_unpack_positive_integer(msgpack_object obj) {
  /*
  mxArray *ret = mxCreateNumericMatrix(1,1, mxUINT64_CLASS, mxREAL);
  uint64_t *ptr = (uint64_t *)mxGetPr(ret);
  *ptr = obj.via.u64;
  return ret;
  */
  return mxCreateDoubleScalar((double)obj.via.u64);
}

mxArray* mex_unpack_negative_integer(msgpack_object obj) {
  /*
  mxArray *ret = mxCreateNumericMatrix(1,1, mxINT64_CLASS, mxREAL);
  int64_t *ptr = (int64_t *)mxGetPr(ret);
  *ptr = obj.via.i64;
  return ret;
  */
  return mxCreateDoubleScalar((double)obj.via.i64);
}

mxArray* mex_unpack_double(msgpack_object obj) {
/*
  mxArray* ret = mxCreateDoubleMatrix(1,1, mxREAL);
  double *ptr = (double *)mxGetPr(ret);
  *ptr = obj.via.dec;
  return ret;
*/
  return mxCreateDoubleScalar(obj.via.dec);
}

mxArray* mex_unpack_raw(msgpack_object obj) {

  mxArray* ret = mxCreateNumericMatrix(1,obj.via.raw.size, mxUINT8_CLASS, mxREAL);
  uint8_t *ptr = (uint8_t*)mxGetPr(ret); 
  memcpy(ptr, obj.via.raw.ptr, obj.via.raw.size * sizeof(uint8_t));

/*
  const char **str_array = (const char **)mxMalloc(sizeof(const char *));
  str_array[0] = obj.via.raw.ptr;
  mxArray* ret = mxCreateCharMatrixFromStrings(1, str_array);
  mxFree((void *)str_array);
  */

  return ret;
}

mxArray* mex_unpack_nil(msgpack_object obj) {
  /*
  return mxCreateCellArray(0,0);
  */
  return mxCreateDoubleScalar(0);
}

mxArray* mex_unpack_map(msgpack_object obj) {
  uint32_t nfields = obj.via.map.size;
  char **field_name = (char **)mxCalloc(nfields, sizeof(char *));
  for (int i = 0; i < nfields; i++) {
    struct msgpack_object_kv obj_kv = obj.via.map.ptr[i];
    if (obj_kv.key.type == MSGPACK_OBJECT_RAW) {
      /* the raw size from msgpack only counts actual characters
       * but C char array need end with \0 */
      field_name[i] = (char*)mxCalloc(obj_kv.key.via.raw.size + 1, sizeof(char));
      memcpy((char*)field_name[i], obj_kv.key.via.raw.ptr, obj_kv.key.via.raw.size * sizeof(char));
    } else {
      mexPrintf("not string key\n");
    }
  }
  mxArray *ret = mxCreateStructMatrix(1, 1, obj.via.map.size, (const char**)field_name);
  msgpack_object ob;
  for (int i = 0; i < nfields; i++) {
    int ifield = mxGetFieldNumber(ret, field_name[i]);
    ob = obj.via.map.ptr[i].val;
    mxSetFieldByNumber(ret, 0, ifield, (*unPackMap[ob.type])(ob));
  }
  for (int i = 0; i < nfields; i++)
    mxFree((void *)field_name[i]);
  mxFree(field_name); 
  return ret;
}

mxArray* mex_unpack_array(msgpack_object obj) {
  /* validate array element type */
  int types = 0;
  int unique_type = -1;
  for (int i = 0; i < obj.via.array.size; i++)
    if ((obj.via.array.ptr[i].type > 0) && (obj.via.array.ptr[i].type < 5) &&
        (obj.via.array.ptr[i].type != unique_type)) {
      unique_type = obj.via.array.ptr[i].type;
      types ++;
    }
  if (types == 1) {
    mxArray *ret = NULL;
    bool * ptrb = NULL;
    double * ptrd = NULL;
    int64_t * ptri = NULL;
    uint64_t * ptru = NULL;
    switch (unique_type) {
      // TODO: if a unique type, then we should just memcpy...
      case 1:
        ret = mxCreateLogicalMatrix(1, obj.via.array.size);
        ptrb = (bool*)mxGetPr(ret);
        for (int i = 0; i < obj.via.array.size; i++) ptrb[i] = obj.via.array.ptr[i].via.boolean;
        break;
      case 2:
        ret = mxCreateNumericMatrix(1, obj.via.array.size, mxUINT64_CLASS, mxREAL);
        ptru = (uint64_t*)mxGetPr(ret);
        for (int i = 0; i < obj.via.array.size; i++) ptru[i] = obj.via.array.ptr[i].via.u64;
        break;
      case 3:
        ret = mxCreateNumericMatrix(1, obj.via.array.size, mxINT64_CLASS, mxREAL);
        ptri = (int64_t*)mxGetPr(ret);
        for (int i = 0; i < obj.via.array.size; i++) ptri[i] = obj.via.array.ptr[i].via.i64;
        break;
      case 4:
        ret = mxCreateNumericMatrix(1, obj.via.array.size, mxDOUBLE_CLASS, mxREAL);
        ptrd = mxGetPr(ret);
        for (int i = 0; i < obj.via.array.size; i++) ptrd[i] = obj.via.array.ptr[i].via.dec;
        break;
      default:
        break;
    }
    return ret;
  }
  else {
    // just make them all double
    mxArray *ret = mxCreateNumericMatrix(1, obj.via.array.size, mxDOUBLE_CLASS, mxREAL);
    double *ptrd = mxGetPr(ret);
    double val;
    for (int i = 0; i < obj.via.array.size; i++){
      msgpack_object ob = obj.via.array.ptr[i];
      switch (ob.type) {
        case 2:
        val = (double)obj.via.array.ptr[i].via.u64;
        break;
        case 3:
        val = (double)obj.via.array.ptr[i].via.i64;
        break;
        case 4:
        val = (double)obj.via.array.ptr[i].via.dec;
        break;
        default:
        val = 13.37;
        break;
      }
      ptrd[i] = val;
    }
    /*
    mxArray *ret = mxCreateCellMatrix(1, obj.via.array.size);
    for (int i = 0; i < obj.via.array.size; i++) {
      msgpack_object ob = obj.via.array.ptr[i];
      mxSetCell(ret, i, (*unPackMap[ob.type])(ob));
    }
    */
    return ret;
  }
}

void mex_unpack(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) 
{
  const char *str = (const char*)mxGetPr(prhs[0]);
  int size = mxGetM(prhs[0]) * mxGetN(prhs[0]);

  /* deserializes it. */
  size_t offset = 0;
  msgpack_unpacked msg;
  msgpack_unpacked_init(&msg);
  if (!msgpack_unpack_next(&msg, str, size, &offset))
    mexErrMsgTxt("unpack error");

  /* prints the deserialized object. */
  msgpack_object obj = msg.data;

  plhs[0] = (*unPackMap[obj.type])(obj);
  plhs[1] = mxCreateDoubleScalar(offset);
}

void mex_pack_unknown(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  msgpack_pack_nil(pk);
}

void mex_pack_void(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  msgpack_pack_nil(pk);
}

void mex_pack_function(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  msgpack_pack_nil(pk);
}

void mex_pack_single(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nElements = mxGetNumberOfElements(prhs);
  float *data = (float*)mxGetPr(prhs);
  if (nElements > 1) msgpack_pack_array(pk, nElements);
  for (int i = 0; i < nElements; i++) {
    msgpack_pack_float(pk, data[i]);
  }
}

void mex_pack_double(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nElements = mxGetNumberOfElements(prhs);
  double *data = mxGetPr(prhs);
  if (nElements > 1) msgpack_pack_array(pk, nElements);
  for (int i = 0; i < nElements; i++) {
    msgpack_pack_double(pk, data[i]);
  }
}

void mex_pack_int8(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nElements = mxGetNumberOfElements(prhs);
  int8_t *data = (int8_t*)mxGetPr(prhs);
  if (nElements > 1) msgpack_pack_array(pk, nElements);
  for (int i = 0; i < nElements; i++) {
    msgpack_pack_int8(pk, data[i]);
  }
}

void mex_pack_uint8(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nElements = mxGetNumberOfElements(prhs);
  uint8_t *data = (uint8_t*)mxGetPr(prhs);
  if (nElements > 1) msgpack_pack_array(pk, nElements);
  for (int i = 0; i < nElements; i++) {
    msgpack_pack_uint8(pk, data[i]);
  }
}

void mex_pack_int16(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nElements = mxGetNumberOfElements(prhs);
  int16_t *data = (int16_t*)mxGetPr(prhs);
  if (nElements > 1) msgpack_pack_array(pk, nElements);
  for (int i = 0; i < nElements; i++) {
    msgpack_pack_int16(pk, data[i]);
  }
}

void mex_pack_uint16(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nElements = mxGetNumberOfElements(prhs);
  uint16_t *data = (uint16_t*)mxGetPr(prhs);
  if (nElements > 1) msgpack_pack_array(pk, nElements);
  for (int i = 0; i < nElements; i++) {
    msgpack_pack_uint16(pk, data[i]);
  }
}

void mex_pack_int32(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nElements = mxGetNumberOfElements(prhs);
  int32_t *data = (int32_t*)mxGetPr(prhs);
  if (nElements > 1) msgpack_pack_array(pk, nElements);
  for (int i = 0; i < nElements; i++) {
    msgpack_pack_int32(pk, data[i]);
  }
}

void mex_pack_uint32(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nElements = mxGetNumberOfElements(prhs);
  uint32_t *data = (uint32_t*)mxGetPr(prhs);
  if (nElements > 1) msgpack_pack_array(pk, nElements);
  for (int i = 0; i < nElements; i++) {
    msgpack_pack_uint32(pk, data[i]);
  }
}

void mex_pack_int64(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nElements = mxGetNumberOfElements(prhs);
  int64_t *data = (int64_t*)mxGetPr(prhs);
  if (nElements > 1) msgpack_pack_array(pk, nElements);
  for (int i = 0; i < nElements; i++) {
    msgpack_pack_int64(pk, data[i]);
  }
}

void mex_pack_uint64(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nElements = mxGetNumberOfElements(prhs);
  uint64_t *data = (uint64_t*)mxGetPr(prhs);
  if (nElements > 1) msgpack_pack_array(pk, nElements);
  for (int i = 0; i < nElements; i++) {
    msgpack_pack_uint64(pk, data[i]);
  }
}

void mex_pack_logical(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nElements = mxGetNumberOfElements(prhs);
  bool *data = mxGetLogicals(prhs);
  if (nElements > 1) msgpack_pack_array(pk, nElements);
  for (int i = 0; i < nElements; i++)
    (data[i])? msgpack_pack_true(pk) : msgpack_pack_false(pk);
}

void mex_pack_char(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  mwSize str_len = mxGetNumberOfElements(prhs);
  
  /* Add the NULL terminator for MATLAB */
  char *buf = (char *)mxCalloc(str_len+1, sizeof(char));
  if (mxGetString(prhs, buf, str_len+1) != 0)
    mexErrMsgTxt("Could not convert to C string data");

  /* Don't use the null terminator for raw packing */
  msgpack_pack_raw(pk, str_len);
  msgpack_pack_raw_body(pk, buf, str_len);

  mxFree(buf);

/* uint8 input
  int nElements = mxGetNumberOfElements(prhs);
  uint8_t *data = (uint8_t*)mxGetPr(prhs); 
*/
  /* matlab char type is actually uint16 -> 2 * uint8 */
/* uint8 input
  msgpack_pack_raw(pk, nElements * 2);
  msgpack_pack_raw_body(pk, data, nElements * 2);
*/
}

void mex_pack_cell(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nElements = mxGetNumberOfElements(prhs);
  if (nElements > 1) msgpack_pack_array(pk, nElements);
  for (int i = 0; i < nElements; i++) {
    mxArray * pm = mxGetCell(prhs, i);
    (*PackMap[mxGetClassID(pm)])(pk, nrhs, pm);
  }
}

void mex_pack_struct(msgpack_packer *pk, int nrhs, const mxArray *prhs) {
  int nField = mxGetNumberOfFields(prhs);
  if (nField > 1) msgpack_pack_map(pk, nField);
  const char* fname = NULL;
  int fnameLen = 0;
  int ifield = 0;
  for (int i = 0; i < nField; i++) {
    fname = mxGetFieldNameByNumber(prhs, i);
    fnameLen = strlen(fname);
    msgpack_pack_raw(pk, fnameLen);
    msgpack_pack_raw_body(pk, fname, fnameLen);
    ifield = mxGetFieldNumber(prhs, fname);
    mxArray* pm = mxGetFieldByNumber(prhs, 0, ifield);
    (*PackMap[mxGetClassID(pm)])(pk, nrhs, pm);
  }
}

void mex_pack(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* creates buffer and serializer instance. */
  msgpack_sbuffer* buffer = msgpack_sbuffer_new();
  msgpack_packer* pk = msgpack_packer_new(buffer, msgpack_sbuffer_write);

  for (int i = 0; i < nrhs; i ++)
    (*PackMap[mxGetClassID(prhs[i])])(pk, nrhs, prhs[i]);

  plhs[0] = mxCreateNumericMatrix(1, buffer->size, mxUINT8_CLASS, mxREAL);
  memcpy(mxGetPr(plhs[0]), buffer->data, buffer->size * sizeof(uint8_t));

  /* cleaning */
  msgpack_sbuffer_free(buffer);
  msgpack_packer_free(pk);
}

void mex_pack_raw(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* creates buffer and serializer instance. */
  msgpack_sbuffer* buffer = msgpack_sbuffer_new();
  msgpack_packer* pk = msgpack_packer_new(buffer, msgpack_sbuffer_write);

  for (int i = 0; i < nrhs; i ++) {
    size_t nElements = mxGetNumberOfElements(prhs[i]);
    size_t sElements = mxGetElementSize(prhs[i]);
    uint8_t *data = (uint8_t*)mxGetPr(prhs[i]);
    msgpack_pack_raw(pk, nElements * sElements);
    msgpack_pack_raw_body(pk, data, nElements * sElements);
  }

  plhs[0] = mxCreateNumericMatrix(1, buffer->size, mxUINT8_CLASS, mxREAL);
  memcpy(mxGetPr(plhs[0]), buffer->data, buffer->size * sizeof(uint8_t));

  /* cleaning */
  msgpack_sbuffer_free(buffer);
  msgpack_packer_free(pk);
}

void mex_unpacker_set_cell(mxArray *plhs, int nlhs, mxArrayRes *res) {
  if (nlhs > 0)
    mex_unpacker_set_cell(plhs, nlhs-1, res->next);
  mxSetCell(plhs, nlhs, res->res);
}

void mex_unpacker(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  mxArrayRes * ret = NULL;
  int npack = 0;
  /* Init deserialize using msgpack_unpacker */
  msgpack_unpacker pac;
  msgpack_unpacker_init(&pac, MSGPACK_UNPACKER_INIT_BUFFER_SIZE);

  const char *str = (const char*)mxGetPr(prhs[0]);
  int size = mxGetM(prhs[0]) * mxGetN(prhs[0]);
  if (size) {
    /* feeds the buffer */
    msgpack_unpacker_reserve_buffer(&pac, size);
    memcpy(msgpack_unpacker_buffer(&pac), str, size);
    msgpack_unpacker_buffer_consumed(&pac, size);
  
    /* start streaming deserialization */
    msgpack_unpacked msg;
    msgpack_unpacked_init(&msg);
    for (;msgpack_unpacker_next(&pac, &msg); npack++) {
      /* prints the deserialized object. */
      msgpack_object obj = msg.data;
      ret = mxArrayRes_new(ret, (*unPackMap[obj.type])(obj));
    }
    /* set cell for output */
    plhs[0] = mxCreateCellMatrix(npack, 1);
    mex_unpacker_set_cell((mxArray *)plhs[0], npack-1, ret);
  }

  mxArrayRes_free(ret);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  static bool init = false;
  /* Init unpack functions Map */
  if (!init) {
    unPackMap[MSGPACK_OBJECT_NIL] = mex_unpack_nil;
    unPackMap[MSGPACK_OBJECT_BOOLEAN] = mex_unpack_boolean;
    unPackMap[MSGPACK_OBJECT_POSITIVE_INTEGER] = mex_unpack_positive_integer;
    unPackMap[MSGPACK_OBJECT_NEGATIVE_INTEGER] = mex_unpack_negative_integer;
    unPackMap[MSGPACK_OBJECT_DOUBLE] = mex_unpack_double;
    unPackMap[MSGPACK_OBJECT_RAW] = mex_unpack_raw;
    unPackMap[MSGPACK_OBJECT_ARRAY] = mex_unpack_array;
    unPackMap[MSGPACK_OBJECT_MAP] = mex_unpack_map; 

    PackMap[mxUNKNOWN_CLASS] = mex_pack_unknown;
    PackMap[mxVOID_CLASS] = mex_pack_void;
    PackMap[mxFUNCTION_CLASS] = mex_pack_function;
    PackMap[mxCELL_CLASS] = mex_pack_cell;
    PackMap[mxSTRUCT_CLASS] = mex_pack_struct;
    PackMap[mxLOGICAL_CLASS] = mex_pack_logical;
    PackMap[mxCHAR_CLASS] = mex_pack_char;
    PackMap[mxDOUBLE_CLASS] = mex_pack_double;
    PackMap[mxSINGLE_CLASS] = mex_pack_single;
    PackMap[mxINT8_CLASS] = mex_pack_int8;
    PackMap[mxUINT8_CLASS] = mex_pack_uint8;
    PackMap[mxINT16_CLASS] = mex_pack_int16;
    PackMap[mxUINT16_CLASS] = mex_pack_uint16;
    PackMap[mxINT32_CLASS] = mex_pack_int32;
    PackMap[mxUINT32_CLASS] = mex_pack_uint32;
    PackMap[mxINT64_CLASS] = mex_pack_int64;
    PackMap[mxUINT64_CLASS] = mex_pack_uint64;

    mexAtExit(mexExit);
    init = true;
  }

  if ((nrhs < 1) || (!mxIsChar(prhs[0])))
    mexErrMsgTxt("Need to input string argument");
  char *fname = mxArrayToString(prhs[0]);
  char *flag = new char[10];
  if (strcmp(fname, "pack") == 0) {
    if (mxIsChar(prhs[nrhs-1])) flag = mxArrayToString(prhs[nrhs-1]);
    if (strcmp(flag, "raw") == 0)
      mex_pack_raw(nlhs, plhs, nrhs-2, prhs+1);
    else
      mex_pack(nlhs, plhs, nrhs-1, prhs+1);
  }
  else if (strcmp(fname, "unpack") == 0)
    mex_unpack(nlhs, plhs, nrhs-1, prhs+1);
  else if (strcmp(fname, "unpacker") == 0)
    mex_unpacker(nlhs, plhs, nrhs-1, prhs+1);
  else
    mexErrMsgTxt("Unknown function argument");
}

