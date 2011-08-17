/*
  ret = dcmSensor(args);

  mex -O dcmSensor.cpp -I/usr/local/boost -lrt

  Matlab MEX file to access shared memory using Boost interprocess
  Author: Stephen McGill w/ Daniel Lee
*/

#include "Python.h"
#include <boost/interprocess/managed_shared_memory.hpp>
using namespace boost::interprocess;

static int width = 640;
static int height = 480;

static const char visionShmName[] = "vcmImage";
static managed_shared_memory visionShm;
static const char ballShmName[] = "vcmBall";
static managed_shared_memory ballShm;


static int convert_yuv_to_rgb_pixel(int y, int u, int v)
{
	unsigned int pixel32 = 0;
	unsigned char *pixel = (unsigned char *)&pixel32;
	int r, g, b;

	r = y + (1.370705 * (v-128));
	g = y - (0.698001 * (v-128)) - (0.337633 * (u-128));
	b = y + (1.732446 * (u-128));

	if(r > 255) r = 255;
	if(g > 255) g = 255;
	if(b > 255) b = 255;
	if(r < 0) r = 0;
	if(g < 0) g = 0;
	if(b < 0) b = 0;

	pixel[0] = b * 220 / 256;
	pixel[1] = g * 220 / 256;
	pixel[2] = r * 220 / 256;
	pixel[3] = 0xFF;

	return pixel32;
}


static int convert_yuv_to_rgb_buffer(unsigned char *yuv, unsigned char *rgb, unsigned int width, unsigned int height) {
	unsigned int in, out = 0;
	unsigned int pixel_16;
	unsigned int pixel32;
	int y0, u, y1, v;

	// Different pointer to the rgb map
	int* rgb32 = (int*)rgb;

	// Each YUYV takes four bytes to represent two pixels
	for(in = 0; in < width * height * 2; in += 4) {
		pixel_16 =
			yuv[in + 3] << 24 |
			yuv[in + 2] << 16 |
			yuv[in + 1] <<  8 |
			yuv[in + 0];

		y0 = (pixel_16 & 0x000000ff);
		u  = (pixel_16 & 0x0000ff00) >>  8;
		y1 = (pixel_16 & 0x00ff0000) >> 16;
		v  = (pixel_16 & 0xff000000) >> 24;

		pixel32 = convert_yuv_to_rgb_pixel(y0, u, v);
		rgb32[out++] = pixel32;

		// Grab the RGB value of the 
		pixel32 = convert_yuv_to_rgb_pixel(y1, u, v);
		rgb32[out++] = pixel32;

	}

	return 0;
}

static int convert_label_to_rgb_buffer(unsigned char *label, unsigned char *rgb, unsigned int width, unsigned int height) {
	unsigned int in, out = 0;

	for(in = 0; in < width * height / 2; in++) {
		if( label[in] == 0x01 ){//red
			rgb[out++] = 0;//b
			rgb[out++] = 0;//g
			rgb[out++] = 0xFF;//r
			rgb[out++] = 0xFF;//qimage rgb32 format
		} else {//white
			rgb[out++] = 0xFF;
			rgb[out++] = 0xFF;
			rgb[out++] = 0xFF;
			rgb[out++] = 0xFF;
		}
	}

	return 0;
}









static PyObject* vcm_image(PyObject *self, PyObject *args) {

  static bool init = false;
  if (!init) {
    fprintf(stdout, "Attaching shm: %s", visionShmName);
    visionShm = managed_shared_memory(open_only, visionShmName);
    init = true;
  }

  // The SHM key should be given to us.  We want big_image
  const char* key;
  // If not enough arguments, then return NULL - error
  if ( !PyArg_ParseTuple(args, "s", &key) )
    return PyErr_Format( PyExc_StandardError, "Bad argument (%s)", key );

  // Try to find the given key
  std::pair<double *, std::size_t> ret;
  ret = visionShm.find<double>(key);
  // Get the pointer to the memory from this shm key
  unsigned char *yuyv = (unsigned char*)ret.first;
  //int n = ret.second;
  // Check if the key was found
  if( yuyv == NULL )
    return PyErr_Format( PyExc_StandardError, "YUYV pointer was not found argument (%s)", key );

  // Convert the yuyv buffer to RGB space
  // 3 bytes for each rgb pixel
  unsigned char *rgb = (unsigned char *) PyMem_Malloc( width * height * 4 ); /* for I/O */
  if (rgb == NULL)
    return PyErr_NoMemory();

  // Perform the conversion, placing into the allocated buffer
  convert_yuv_to_rgb_buffer(yuyv, rgb, width, height);

  // Convert to a Python object and return it
  int len = width * height * 4;// Right? There should be 3 bytes (characaters) for each pixel
  PyObject *res;
  res = PyString_FromStringAndSize( (char*)rgb, len );

  // Free our memory before returning
  PyMem_Free( rgb ); /* allocated with PyMem_Malloc */
  return res;
}

static PyObject* vcm_label(PyObject *self, PyObject *args) {

  static bool init = false;
  if (!init) {
    fprintf(stdout, "Attaching shm: %s", visionShmName);
    visionShm = managed_shared_memory(open_only, visionShmName);
    init = true;
  }

  // The SHM key should be given to us.  We want big_image
  const char* key;
  // If not enough arguments, then return NULL - error
  if ( !PyArg_ParseTuple(args, "s", &key) )
    return PyErr_Format( PyExc_StandardError, "Bad argument (%s)", key );

  // Try to find the given key
  std::pair<double *, std::size_t> ret;
  ret = visionShm.find<double>(key);
  // Get the pointer to the memory from this shm key
  unsigned char *label = (unsigned char*)ret.first;
  //int n = ret.second;
  // Check if the key was found
  if( label == NULL )
    return PyErr_Format( PyExc_StandardError, "Label pointer was not found argument (%s)", key );

  // Convert the yuyv buffer to RGB space
  // 3 bytes for each rgb pixel
  unsigned char *rgb = (unsigned char *) PyMem_Malloc( width * height * 4 ); /* for I/O */
  if (rgb == NULL)
    return PyErr_NoMemory();

  // Perform the conversion, placing into the allocated buffer
  convert_label_to_rgb_buffer(label, rgb, width, height);

  // Convert to a Python object and return it
  int len = width * height * 4;// Right? There should be 3 bytes (characaters) for each pixel
  PyObject *res;
  res = PyString_FromStringAndSize( (char*)rgb, len );

  // Free our memory before returning
  PyMem_Free( rgb ); /* allocated with PyMem_Malloc */
  return res;
}

static PyObject* vcm_ball(PyObject *self, PyObject *args) {

  static bool init = false;
  if (!init) {
    fprintf(stdout, "Attaching shm: %s\n", ballShmName);
    ballShm = managed_shared_memory(open_only, ballShmName);
    init = true;
  }

  // The SHM key should be given to us.  We want big_image
  const char* key;
  // If not enough arguments, then return NULL - error
  if ( !PyArg_ParseTuple(args, "s", &key) )
    return PyErr_Format( PyExc_StandardError, "Bad argument (%s)", key );

  // Try to find the given key
  std::pair<double *, std::size_t> ret;
  ret = ballShm.find<double>(key);
  // Get the pointer to the memory from this shm key
  double *pr = (double*)ret.first;
  int n = ret.second;
  // Check if the key was found
  if( pr == NULL )
    return PyErr_Format( PyExc_StandardError, "Pointer was not found argument (%s)", key );

  // Convert to a Python object and return it
  PyObject *res;
  res = PyList_New( n );
  for (int i = 0; i < n; i++) {
    PyList_SetItem( res, i, PyFloat_FromDouble(pr[i]) );
  }

  return res;
}


static PyMethodDef vcmMethods[] = {
    {"image",  vcm_image, METH_VARARGS, "Grab an image from shm."},
    {"label",  vcm_label, METH_VARARGS, "Grab a label from shm."},
    {"ball",  vcm_ball, METH_VARARGS, "Get the ball properties from shm."},
    {NULL, NULL, 0, NULL}        /* Sentinel */
};

PyMODINIT_FUNC initvcm(void) {
    (void) Py_InitModule("vcm", vcmMethods);
}

