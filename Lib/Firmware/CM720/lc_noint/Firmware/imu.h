#ifndef __IMU_H
#define __IMU_H

float* imu_get_angle();

int imu_filter_gyr(uint16_t *gyrRaw, float dt);
int imu_filter_acc(uint16_t *accRaw, float dt);

#endif // __IMU_H
