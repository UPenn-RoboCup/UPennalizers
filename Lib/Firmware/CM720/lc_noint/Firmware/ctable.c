#include "ctable.h"

struct ControlTable controlTable;
char *controlTablePtr = (char *) &controlTable;

/*
#define NUM_CONTROL_ENTRIES 16
uint8_t controlTable[NUM_CONTROL_ENTRIES];

#define EEPROM_BASE_ADDRESS 11
static void updateEEPROM(void)
{
  eeprom_write_byte((uint8_t*)(EEPROM_BASE_ADDRESS - 1), 16);
}
*/

void ctable_init(void)
{
  int i;
  // Default parameters
  controlTable.model = 0;
  controlTable.version = 1;
  controlTable.id = 128;
  controlTable.led = 0;

  controlTable.nServo = 24;
  for (i = 0; i < controlTable.nServo; i++) {
    controlTable.idMap[i] = i;
  }

  controlTable.addrRead = 36; // Present position
  controlTable.lenRead = 2;
}

void ctable_write_eeprom()
{

}

