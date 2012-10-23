#ifndef CONTROL_TABLE_H
#define CONTROL_TABLE_H

#include <stddef.h>
#include <stdint.h>

#define NUM_ADC_CHANNELS   8

#define SYNC_WRITE_ID      0xFE

#define MAX_NUM_SERVOS     24
#define NUM_DIGITAL_INPUTS 4
#define DEFAULT_ID         128
#define FIRMWARE_VERSION   1
#define DEFAULT_BAUD_RATE  0

#define SERVO_FEEDBACK_OFFSET 36   //position offset in dynamixel table

//set any unused ids to 255, so that they are not queried
#define SKIP_ID            255

//The mode bits enable/disable functionality. 
//Set mode to 0 for manual mode
enum { 
       MODE_BIT_POSITION_FEEDBACK = 0,
       MODE_BIT_VELOCITY_FEEDBACK,
       MODE_BIT_TORQUE_FEEDBACK,
       MODE_BIT_SYNC_WRITE_POSITION,
       MODE_BIT_SYNC_WRITE_VELOCITY,
       MODE_BIT_SYNC_WRITE_TORQUE,
       MODE_BIT_READ_ADC
     };

#define FEEDBACK_READ_MASK (_BV(MODE_BIT_POSITION_FEEDBACK) | _BV(MODE_BIT_VELOCITY_FEEDBACK) | _BV(MODE_BIT_TORQUE_FEEDBACK) )
#define SYNC_WRITE_MASK (_BV(MODE_BIT_SYNC_WRITE_POSITION) | _BV(MODE_BIT_SYNC_WRITE_VELOCITY) | _BV(MODE_BIT_SYNC_WRITE_TORQUE))

typedef struct
{
  //8 bytes
  uint8_t version;
  uint8_t id;
  uint8_t baud;
  uint8_t mode;
  uint8_t state;
  uint8_t currServo;
  uint8_t dummy1;
  uint8_t dummy2;
  
  uint8_t  idMap[MAX_NUM_SERVOS];         //24 bytes

  uint16_t goalPos[MAX_NUM_SERVOS];       //48 bytes
  uint16_t goalVel[MAX_NUM_SERVOS];       //48 bytes
  uint16_t currPos[MAX_NUM_SERVOS];       //48 bytes
  uint16_t adcVals[NUM_ADC_CHANNELS];     //16 bytes
  float rpy[3];                           //12 bytes
  uint8_t  digitalIn[NUM_DIGITAL_INPUTS]; //4 bytes

  //counters
  uint16_t currPosCntr;                   //2 bytes
  uint16_t adcCntr;                       //2 bytes
} ControlTable;
 
#define MODE_MANUAL                   0
#define DEFAULT_MODE                  ( _BV(MODE_BIT_POSITION_FEEDBACK) )

#define VERSION_OFFSET                offsetof(ControlTable,version)
#define ID_OFFSET                     offsetof(ControlTable,id)
#define BAUD_RATE_OFFSET              offsetof(ControlTable,baud)
#define MODE_OFFSET                   offsetof(ControlTable,mode)
#define STATE_OFFSET                  offsetof(ControlTable,state)
#define CURR_SERVO_OFFSET             offsetof(ControlTable,currServo)
#define ID_MAP_OFFSET                 offsetof(ControlTable,idMap)
#define GOAL_POSITION_VALS_OFFSET     offsetof(ControlTable,goalPos)
#define GOAL_VELOCITY_VALS_OFFSET     offsetof(ControlTable,goalVel)
#define CURR_POSITION_VALS_OFFSET     offsetof(ControlTable,currPos)
#define ADC_VALS_OFFSET               offsetof(ControlTable,adcVals)
#define RPY_VALS_OFFSET               offsetof(ControlTable,rpy)
#define DIGITAL_IN_VALS_OFFSET        offsetof(ControlTable,digitalIn)
#define CURR_POS_CNTR_OFFSET          offsetof(ControlTable,currPosCntr)
#define ADC_CNTR_OFFSET               offsetof(ControlTable,currPosCntr)
#define CONTROL_TABLE_SIZE            sizeof(ControlTable)


#define INSTRUCTION_PING           0x01
#define INSTRUCTION_READ_DATA      0x02
#define INSTRUCTION_WRITE_DATA     0x03
#define INSTRUCTION_REG_WRITE      0x04
#define INSTRUCTION_ACTION         0x05
#define INSTRUCTION_RESET          0x06
#define INSTRUCTION_SYNC_WRITE     0x83


enum { STATE_IDLE = 0,
       STATE_WAITING_FOR_SYNC_WRITE_TRIGGER,
       STATE_WAITING_FOR_FEEDBACK_TRIGGER,
       STATE_WAITING_FOR_FEEDBACK_RESPONSE,
       STATE_AFTER_SYNC_WRITE_PAUSE
     };
     

#define NO_ERROR 0

enum { ERROR_BIT_INPUT_VOLTAGE = 0,
       ERROR_BIT_ANGLE_LIMIT,
       ERROR_BIT_OVERHEATING,
       ERROR_BIT_RANGE,
       ERROR_BIT_CHECKSUM,
       ERROR_BIT_OVERLOAD,
       ERROR_BIT_INSTRUCTION,
       ERROR_BIT_INVALID_MODE
     };


#endif //CONTROL_TABLE_H

