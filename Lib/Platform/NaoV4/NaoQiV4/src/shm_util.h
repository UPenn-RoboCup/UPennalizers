#ifndef shm_util_h_DEFINED
#define shm_util_h_DEFINED

static const char sensorShmName[] = "dcmSensor";
static const char actuatorShmName[] = "dcmActuator";

int sensor_shm_open();
int sensor_shm_close();
double *sensor_shm_get_ptr(const char *key);
double *sensor_shm_set_ptr(const char *key, int nval);

int actuator_shm_open();
int actuator_shm_close();
double *actuator_shm_get_ptr(const char *key);
double *actuator_shm_set_ptr(const char *key, int nval);

#endif
