#include "sensor_process.h"
#include "shm_util.h"

#include <alcommon/albroker.h>
#include <almemoryfastaccess/almemoryfastaccess.h>

#include <vector>
#include <string>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/time.h>

using namespace AL;

typedef struct {
  double *shmPtr;
  float *dcmPtr;
} structPtrCopy;

static std::vector<structPtrCopy> sensorPtrCopy;

static double *sensorPtrTime;
static double *sensorPtrCount;
static double *sensorPtrButton;

static const unsigned int nButtonShutdown = 350; // 3.5 sec
static const char* shutdownCommand = "/sbin/shutdown -h now";

int sensor_process_init(ALPtr<ALBroker> pBroker) {
  ALMemoryFastAccess memoryFastAccess;

  int ret = sensor_shm_open();
  if (ret) {
    std::cerr << "Could not open sensor shm" << std::endl;
    return ret;
  }

  sensorPtrCopy.clear();

  // Setup corresponding DCM and SHM pointers
  struct structSensorKeys *sensorKey = sensorKeys;
  while (sensorKey->key != NULL) {
		printf("Setting up sensor key: %s[%d]\n", sensorKey->key, sensorKey->size);
    int nval = sensorKey->size;
    // Pointer in shared memory
    double *pr = sensor_shm_set_ptr(sensorKey->key, nval);

    // If there are corresponding DCM names, setup pointer vectors:
    if (sensorKey->names != NULL) {
      for (int i = 0; i < nval; i++) {
	structPtrCopy ptrCopy;
	ptrCopy.shmPtr = pr+i;
	std::string name(sensorKey->names[i]);
	float *pDcm = (float *)
	  memoryFastAccess.getDataPtr(pBroker, name, false);
	ptrCopy.dcmPtr = pDcm;
	sensorPtrCopy.push_back(ptrCopy);
      }
    }

    sensorKey++;
  }

  sensorPtrTime = sensor_shm_get_ptr("time");
  if (sensorPtrTime == NULL) {
    std::cerr << "Could not get sensor shm time pointer" << std::endl;
    return -1;
  }

  sensorPtrCount = sensor_shm_get_ptr("count");
  if (sensorPtrCount == NULL) {
    std::cerr << "Could not get sensor shm count pointer" << std::endl;
    return -1;
  }

  sensorPtrButton = sensor_shm_get_ptr("button");
  if (sensorPtrButton == NULL) {
    std::cerr << "Could not get sensor shm button pointer" << std::endl;
    return -1;
  }

  return 0;
}

int sensor_process() {
  static unsigned int count = 0;
  static unsigned int nButton = 0;

  count++;
  *sensorPtrCount = count;

  struct timeval tv;
  gettimeofday(&tv, NULL);
  double t = tv.tv_sec + 1E-6*tv.tv_usec;
  *sensorPtrTime = t;

  if (*sensorPtrButton > 0) {
    nButton++;
    if (nButton == nButtonShutdown) {
      std::cout << "DCM sensor: system shutting down..." << std::endl;
      int ret = system(shutdownCommand);
      if (WIFSIGNALED(ret) && (WTERMSIG(ret) == SIGINT || WTERMSIG(ret) == SIGQUIT))
        return 0;
    }
  }
  else {
    // Reset button counter
    nButton = 0;
  }

  // Copy DCM values to shared memory:
  int nCopy = sensorPtrCopy.size();
  for (int i = 0; i < nCopy; i++) {
    structPtrCopy &ptrCopy = sensorPtrCopy[i];
    *ptrCopy.shmPtr = *ptrCopy.dcmPtr;
  }
  
  return 0;
}

int sensor_process_exit() {
  sensor_shm_close();

  return 0;
}
