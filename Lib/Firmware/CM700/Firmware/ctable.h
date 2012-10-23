#ifndef __CTABLE_H
#define __CTABLE_H

#include <stdint.h>

#define MAX_DATA 256
#define NUM_SERVO 24
#define NUM_ADC 6
#define NUM_INPUT 4
#define NUM_IMU_ANGLE 3

struct ControlTable {
  uint16_t model;
  uint8_t version;
  uint8_t id;
  uint8_t baudSerial;
  uint8_t baudRS485;
  uint8_t delay;
  uint8_t led;

  uint8_t state;
  uint8_t button;
  uint8_t input[NUM_INPUT];
  uint16_t adc[NUM_ADC];
  uint16_t imuAngle[NUM_IMU_ANGLE];

  uint8_t nServo;
  uint8_t idMap[NUM_SERVO];
  uint8_t addrRead;
  uint8_t lenRead;
  uint8_t dataRead[MAX_DATA];
};

extern struct ControlTable controlTable;
extern char *controlTablePtr;

void ctable_init();
void ctable_write_eeprom();

#endif // __CTABLE_H
