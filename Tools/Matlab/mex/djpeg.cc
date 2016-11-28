/* 
 * (c) 2013 Dan Lee, Alex Kushlyev, Steve McGill, Yida Zhang
 * ddlee@seas.upenn.edu, smcgill3@seas.upenn.edu
 * University of Pennsylvania
 * */

/*
  djpeg.cpp

  To compile:
  mex -O djpeg.cpp -ljpeg

  rgb = djpeg(buf);
*/

#include "mex.h"
#include <jpeglib.h>

static void error_exit(j_common_ptr cinfo)
{
  (*cinfo->err->output_message) (cinfo);
  jpeg_destroy_decompress((j_decompress_ptr) cinfo);
  mexErrMsgTxt("JPEG decompression error");
}

void init_source(j_decompress_ptr cinfo) { }

boolean fill_input_buffer(j_decompress_ptr cinfo)
{
  jpeg_destroy_decompress(cinfo);
  mexPrintf("fill_input_buffer\n");
  return TRUE;
}

void skip_input_data(j_decompress_ptr cinfo, long num_bytes)
{
  if (num_bytes > 0) {
    while (num_bytes > (long) cinfo->src->bytes_in_buffer) {
      num_bytes -= (long) cinfo->src->bytes_in_buffer;
      (void) fill_input_buffer(cinfo);
    }
    cinfo->src->next_input_byte += (size_t) num_bytes;
    cinfo->src->bytes_in_buffer -= (size_t) num_bytes;
  }
}

void term_source(j_decompress_ptr cinfo) { }

static mxArray *
jpeg_to_mxarray_rgb(j_decompress_ptr cinfoPtr)
{
  long row_stride = cinfoPtr->output_width * cinfoPtr->output_components;
  JSAMPARRAY buffer = (*cinfoPtr->mem->alloc_sarray)
    ((j_common_ptr) cinfoPtr, JPOOL_IMAGE, row_stride, 1);

  mwSize dims[3];
  dims[0]  = cinfoPtr->output_height;
  dims[1]  = cinfoPtr->output_width;
  dims[2]  = 3;
    
  mxArray *img = mxCreateNumericArray(3, dims, mxUINT8_CLASS, mxREAL);
  
  uint8_T *pr_r   = (uint8_T *) mxGetPr(img);
  uint8_T *pr_g = pr_r + (dims[0]*dims[1]);
  uint8_T *pr_b  = pr_r + (2*dims[0]*dims[1]);
  
  while (cinfoPtr->output_scanline < cinfoPtr->output_height) {
    int current_row = cinfoPtr->output_scanline; // temp var won't get ++'d
    jpeg_read_scanlines(cinfoPtr, buffer,1); // by jpeg_read_scanlines
    for (int i = 0; i < cinfoPtr->output_width; i++) {   
      int j=(i)*cinfoPtr->output_height+current_row;       
      pr_r[j] = buffer[0][3*i+0];
      pr_g[j] = buffer[0][3*i+1];
      pr_b[j] = buffer[0][3*i+2];
    }
  }
  return img;
}

static mxArray *
jpeg_to_mxarray_gray(j_decompress_ptr cinfoPtr)
{
  long row_stride = cinfoPtr->output_width * cinfoPtr->output_components;
  JSAMPARRAY buffer = (*cinfoPtr->mem->alloc_sarray)
    ((j_common_ptr) cinfoPtr, JPOOL_IMAGE, row_stride, 1);
    
  mwSize dims[2];
  dims[0]  = cinfoPtr->output_height;
  dims[1]  = cinfoPtr->output_width;
    
  mxArray *img = mxCreateNumericArray(2, dims, mxUINT8_CLASS, mxREAL);
  uint8_T *pr_gray = (uint8_T *) mxGetPr(img);

  while (cinfoPtr->output_scanline < cinfoPtr->output_height) {
    int current_row = cinfoPtr->output_scanline; // temp var won't get ++'d
    jpeg_read_scanlines(cinfoPtr, buffer,1); // by jpeg_read_scanlines
    for (int i = 0; i < cinfoPtr->output_width; i++) {   
      int j=(i)*cinfoPtr->output_height+current_row;       
      pr_gray[j]   = buffer[0][i];
    }
  }
  return img;
}


void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[]) { 

  if (nrhs < 1) {
    mexErrMsgTxt("Not enough input arguments");
  }      
  if (!(mxIsUint8(prhs[0]) || mxIsInt8(prhs[0])))
    mexErrMsgTxt("Input must be of type uint8 or int8");

  char *jpegBuf = (char *) mxGetData(prhs[0]);
  unsigned int jpegBufLen = mxGetM(prhs[0])*mxGetN(prhs[0]);

  struct jpeg_decompress_struct cinfo;
  struct jpeg_error_mgr jerr;
  cinfo.err = jpeg_std_error(&jerr);
  jerr.error_exit = error_exit;

  jpeg_create_decompress(&cinfo);
  if (cinfo.src == NULL) {
    cinfo.src = (struct jpeg_source_mgr *)
      (*cinfo.mem->alloc_small) ((j_common_ptr) &cinfo, JPOOL_PERMANENT,
				 sizeof(struct jpeg_source_mgr));
  }
  cinfo.src->bytes_in_buffer = jpegBufLen;
  cinfo.src->next_input_byte = (JOCTET *)jpegBuf;
  cinfo.src->init_source = init_source;
  cinfo.src->fill_input_buffer = fill_input_buffer;
  cinfo.src->skip_input_data = skip_input_data;
  cinfo.src->resync_to_restart = jpeg_resync_to_restart;
  cinfo.src->term_source = term_source;

  jpeg_read_header(&cinfo, TRUE);
  jpeg_start_decompress(&cinfo);
  if (cinfo.output_components == 1) {
    // Grayscale
    plhs[0] = jpeg_to_mxarray_gray(&cinfo);
  }
  else {
    // RGB
    plhs[0] = jpeg_to_mxarray_rgb(&cinfo);
  }
  jpeg_finish_decompress(&cinfo);
  jpeg_destroy_decompress(&cinfo);
  
  return;		
}
