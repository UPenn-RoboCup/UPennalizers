#include "shmmap.h"

#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/mman.h>

struct sensorStruct *pSensor;
struct actuatorStruct *pActuator;

int shmmap_open() {
  int fd;

  /*
  // Create sensor shared memory
  fd = shm_open(sensorShmName, O_CREAT|O_RDWR, S_IRUSR|S_IWUSR);
  if (fd == -1) {
    fprintf(stderr, "Could not open shm: %s\n", sensorShmName);
    return -1;
  }
  if (ftruncate(fd, sizeof(sensorStruct)) == -1) {
    fprintf(stderr, "Could not ftruncate shm: %s\n", sensorShmName);
    close(fd);
    return -1;
  }

  // Map sensor memory
  pSensor = (sensorStruct *) mmap(NULL, sizeof(sensorStruct),
				  PROT_READ|PROT_WRITE, MAP_SHARED,
				  fd, 0);
  close(fd);

  if (pSensor == MAP_FAILED) {
    fprintf(stderr, "Could not mmap sensor shm\n");
    return -1;
  }
  memset(pSensor, 0, sizeof(sensorStruct));
  */

  // Create actuator shared memory
  fd = shm_open(actuatorShmName, O_CREAT|O_RDWR, S_IRUSR|S_IWUSR);
  if (fd == -1) {
    fprintf(stderr, "Could not open shm: %s\n", actuatorShmName);
    return -1;
  }
  if (ftruncate(fd, sizeof(actuatorStruct)) == -1) {
    fprintf(stderr, "Could not ftruncate shm: %s\n", actuatorShmName);
    close(fd);
    return -1;
  }

  // Map actuator memory
  pActuator = (actuatorStruct *) mmap(NULL, sizeof(actuatorStruct),
				      PROT_READ|PROT_WRITE, MAP_SHARED,
				      fd, 0);
  close(fd);

  if (pActuator == MAP_FAILED) {
    fprintf(stderr, "Could not mmap actuator shm\n");
    return -1;
  }
  memset(pActuator, 0, sizeof(actuatorStruct));

  return 0;
}

int shmmap_close() {
  // Unmap shared memory
  if (pSensor != MAP_FAILED) {
    munmap(pSensor, sizeof(sensorStruct));
  }
  if (pActuator != MAP_FAILED) {
    munmap(pActuator, sizeof(actuatorStruct));
  }

  // Remove shared memory
  //  shm_unlink(sensorShmName);
  shm_unlink(actuatorShmName);

  return 0;
}
