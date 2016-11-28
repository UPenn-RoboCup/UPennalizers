/* 
 * (c) 2013 Dan Lee, Alex Kushlyev, Steve McGill, Yida Zhang
 * ddlee@seas.upenn.edu, smcgill3@seas.upenn.edu
 * University of Pennsylvania
 * */

/*
  cjpeg.cpp

  To compile:
  mex -O cjpeg.cpp -ljpeg

  jpg = cjpeg(rgb);
*/

#include "mex.h"
#include <vector>
#include <cstring>
#include <jpeglib.h>

std::vector<unsigned char> destBuf;

static void error_exit(j_common_ptr cinfo)
{
  (*cinfo->err->output_message) (cinfo);
  jpeg_destroy_compress((j_compress_ptr) cinfo);
  mexErrMsgTxt("JPEG compression error");
}

void init_destination(j_compress_ptr cinfo) {
  const unsigned int size = 65536;
  destBuf.resize(size);
  cinfo->dest->next_output_byte = &(destBuf[0]);
  cinfo->dest->free_in_buffer = size;
}

boolean empty_output_buffer(j_compress_ptr cinfo)
{
  unsigned int size = destBuf.size();
  destBuf.resize(2*size);
  cinfo->dest->next_output_byte = &(destBuf[size]);
  cinfo->dest->free_in_buffer = size;

  return TRUE;
}

void term_destination(j_compress_ptr cinfo) {
  /*
  cinfo->dest->next_output_byte = destBuf;
  cinfo->dest->free_in_buffer = destBufSize;
  */
  int len = destBuf.size() - (cinfo->dest->free_in_buffer);
  while (len % 2 != 0)
    destBuf[len++] = 0xFF;

  destBuf.resize(len);
}

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[]) { 

  if (nrhs < 1) {
    mexErrMsgTxt("Not enough input arguments");
  }      
  if ((mxGetNumberOfDimensions(prhs[0]) != 3) || (!mxIsUint8(prhs[0])))
    mexErrMsgTxt("Input must be RGB array");

  int quality = 90;
  if (nrhs >= 2) quality = mxGetScalar(prhs[1]);

  const int *dims = mxGetDimensions(prhs[0]);

  int height = dims[0];
  int width = dims[1];
  uint8_T *prRGB = (uint8_T *) mxGetData(prhs[0]);
  
  struct jpeg_compress_struct cinfo;
  struct jpeg_error_mgr jerr;
  cinfo.err = jpeg_std_error(&jerr);
  jerr.error_exit = error_exit;

  jpeg_create_compress(&cinfo);
  if (cinfo.dest == NULL) {
    cinfo.dest = (struct jpeg_destination_mgr *)
      (*cinfo.mem->alloc_small) ((j_common_ptr) &cinfo, JPOOL_PERMANENT,
				 sizeof(struct jpeg_destination_mgr));
  }
  cinfo.dest->init_destination = init_destination;
  cinfo.dest->empty_output_buffer = empty_output_buffer;
  cinfo.dest->term_destination = term_destination;

  cinfo.image_width = width;
  cinfo.image_height = height;
  cinfo.input_components = 3;
  cinfo.in_color_space = JCS_RGB;
  jpeg_set_defaults(&cinfo);
  jpeg_set_quality(&cinfo, quality, TRUE);
  cinfo.write_JFIF_header = false;
  cinfo.dct_method = JDCT_IFAST;

  jpeg_start_compress(&cinfo, TRUE);
  JSAMPLE row[3*width];
  JSAMPROW row_pointer[1];
  *row_pointer = row;

  while (cinfo.next_scanline < cinfo.image_height) {
    //    printf("cinfo.next_scanline = %d\n", cinfo.next_scanline);
    uint8_T *p = prRGB + cinfo.next_scanline;
    int irow = 0;
    for (int i = 0; i < width; i++) {
      row[irow++] = *p;
      row[irow++] = *(p + height*width);
      row[irow++] = *(p + 2*height*width);
      p += height;
    }
    jpeg_write_scanlines(&cinfo, row_pointer, 1);
  }
  jpeg_finish_compress(&cinfo);
  jpeg_destroy_compress(&cinfo);

  unsigned int destBufSize = destBuf.size();
  plhs[0] = mxCreateNumericMatrix(1, destBufSize, mxUINT8_CLASS, mxREAL);
  memcpy(mxGetData(plhs[0]), &(destBuf[0]), destBufSize);
  
  return;		
}
