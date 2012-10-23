#ifndef __CTABLE_H
#define __CTABLE_H

#include <stdint.h>

#define MAX_DATA 224
#define NUM_SERVO 24

struct ControlTable {
  uint16_t model;
  uint8_t version;
  uint8_t id;
  uint8_t baudSerial; // unused
  uint8_t baudRS485; // unused
  uint8_t delay; // unused

  uint8_t nServo;
  uint8_t idMap[NUM_SERVO];

  uint8_t led;
  uint8_t state; // unused

  uint8_t pad[30];

  uint8_t button;
  uint8_t input[3];
  uint16_t adc[6];
  uint16_t imuAcc[3];
  uint16_t imuGyr[3];
  uint16_t imuAngle[3];

  // addrRead, lenRead, dataRead mimics SYNC_WRITE format
  uint8_t addrRead;
  uint8_t lenRead;
  uint8_t dataRead[MAX_DATA];
};

extern struct ControlTable controlTable;
extern char *controlTablePtr;

void ctable_init();
void ctable_write_eeprom();

#endif // __CTABLE_H
