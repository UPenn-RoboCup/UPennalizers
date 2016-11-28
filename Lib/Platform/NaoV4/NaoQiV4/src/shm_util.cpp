#include "shm_util.h"

#include <boost/interprocess/managed_shared_memory.hpp>
using namespace boost::interprocess;

static int shmSize = 65536;

managed_shared_memory *sensorShm = NULL;
managed_shared_memory *actuatorShm = NULL;

static managed_shared_memory *shm_create(const char* name) {
  // First clear out old shm
  shared_memory_object::remove(name);
  // Get Boost::interprocess managed shared memory object
  managed_shared_memory *shm;
  shm = new managed_shared_memory(open_or_create,
				  name, shmSize);
  return shm;
}

static void shm_destroy(const char* name) {
  shared_memory_object::remove(name);
}

static double *shm_get_ptr(managed_shared_memory *shm, const char *key) {
  // Find key in shm
  std::pair<double*, std::size_t> ret;
  ret = shm->find<double>(key);
  double *pr = ret.first;
  return pr;
}

static double *shm_set_ptr(managed_shared_memory *shm,
			   const char *key, int nval) {
  // Check if key exists in shm
  std::pair<double*, std::size_t> ret;
  ret = shm->find<double>(key);
  double *pr = ret.first;
  int n = ret.second;
  if (pr) {
    if (n == nval) {
      return pr;
    }
    else {
      shm->destroy_ptr(pr);
    }
  }
  return shm->construct<double>(key)[nval](0);
}

int sensor_shm_open() {
  sensorShm = shm_create(sensorShmName);
  if (sensorShm == NULL) {
    return -1;
  }
  return 0;
}

int sensor_shm_close() {
  if (sensorShm) {
    delete sensorShm;
  }
  shm_destroy(sensorShmName);
  return 0;
}

double *sensor_shm_get_ptr(const char *key) {
  return shm_get_ptr(sensorShm, key);
}

double *sensor_shm_set_ptr(const char *key, int nval) {
  return shm_set_ptr(sensorShm, key, nval);
}

int actuator_shm_open() {
  actuatorShm = shm_create(actuatorShmName);
  if (actuatorShm == NULL) {
    return -1;
  }
  return 0;
}

int actuator_shm_close() {
  if (actuatorShm) {
    delete actuatorShm;
  }
  shm_destroy(actuatorShmName);
  return 0;
}

double *actuator_shm_get_ptr(const char *key) {
  return shm_get_ptr(actuatorShm, key);
}

double *actuator_shm_set_ptr(const char *key, int nval) {
  return shm_set_ptr(actuatorShm, key, nval);
}
