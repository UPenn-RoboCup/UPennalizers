#ifndef __CTABLE_H
#define __CTABLE_H

#include <stdint.h>

#define MAX_DATA 224
#define NUM_SERVO 24
#define NUM_ADC 6
#define NUM_INPUT 3
#define NUM_IMU_ANGLE 3
#define DEFAULT_ID 128

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

#define OFFSET_MODEL	                			offsetof(ControlTable,model)
#define OFFSET_VERSION                			offsetof(ControlTable,version)
#define OFFSET_ID                     			offsetof(ControlTable,id)
#define OFFSET_BAUDSERIAL              			offsetof(ControlTable,baudSerial)
#define OFFSET_BAUDRS485               			offsetof(ControlTable,baudrs485)
#define OFFSET_DELAY                  			offsetof(ControlTable,delay)
#define OFFSET_NSERVO						            offsetof(ControlTable,nServo)
#define OFFSET_ID_MAP_OFFSET                offsetof(ControlTable,idMap)
#define OFFSET_LED										     	offsetof(ControlTable,led)
#define OFFSET_STATE										    offsetof(ControlTable,state)
#define OFFSET_PAD										      offsetof(ControlTable,pad)
#define OFFSET_BUTTON				 	              offsetof(ControlTable,button)
#define OFFSET_INPUT				                offsetof(ControlTable,input)
#define OFFSET_ADC									        offsetof(ControlTable,adc)
#define OFFSET_IMUACC									      offsetof(ControlTable,imuAcc)
#define OFFSET_IMUGYR									      offsetof(ControlTable,imuGyr)
#define OFFSET_IMUANGLE								      offsetof(ControlTable,imuAngle)
#define OFFSET_ADDRREAD				              offsetof(ControlTable,addrRead)
#define OFFSET_LENREAD						          offsetof(ControlTable,lenRead)
#define OFFSET_DATAREAD				              offsetof(ControlTable,dataRead)
#define CONTROL_TABLE_SIZE            			sizeof(ControlTable)

typedef struct
{
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

} SubControlTable;

void ctable_init();
void ctable_write_eeprom();

#endif // __CTABLE_H
