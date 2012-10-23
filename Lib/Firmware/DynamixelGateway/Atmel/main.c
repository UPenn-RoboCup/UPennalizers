/*

  Atmel driver for interfacing to Dynamixel Servos.
  
  - Performs continous querying of multiple servos. 
      At 1Mbit/s a single query takes about 1.1ms
  - Performs period sync-write operation to multiple servos
  - Uses a memory map (control table), in similar fashion as Dynamixel 
      servos do (adapted for special use). See ControlTable.h

  uart0         : host (USB) communication
  uart1 (rs485) : communcation with rs485 bus
  timer1      : rs485 response timeout
  timer4      : host packet timeout
  timer5      : ADC timing
  
  
  things to configure: 
  RS485_ENABLE_PIN  //enable rs485 transmitter 
  USB_FLUSH_PIN     //pin that can be connected to DSR on FTDI 
                    //to flush data to PC via toggling pin

  NUM_ADC_CHANNELS  //Currently, the code is set up to wait for trigger from counter5
                    //to start conversion cycle at ADC0 and go until (NUM_ADC_CHANNELS-1)
                    //see counter5.c for trigger frequency setting
  
  Alex Kushleyev , Daniel D. Lee.
  University of Pennsylvania
  akushley@seas.upenn.edu
  
  
  April 2010
*/


#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>
#include <string.h>

#include "uart0.h"
#include "rs485.h"
#include "timer1.h"
#include "timer4.h"
#include "adc.h"

#include "config.h"
#include "DynamixelPacket.h"
#include "attitudeFilter.h"

//packet containers for receiving Dynamixel-type packets
DynamixelPacket hostPacketIn;
DynamixelPacket busPacketIn;


const uint16_t DEFAULT_SERVO_ANGLES[] = {512,512,512,512,512,512,
                                         512,512,512,512,512,512,
                                         512,512,512,512,512,512,
                                         512,512,512,512,512,512};
                                         
const uint16_t DEFAULT_SERVO_VELS[]   = {512,512,512,512,512,512,
                                         512,512,512,512,512,512,
                                         512,512,512,512,512,512,
                                         512,512,512,512,512,512};
                                         

//control table contains all the vital variables for operation
//see ControlTable.h for mapping
ControlTable ctable;
uint8_t * ctablePtr = (uint8_t*)&ctable;


//variables that are flag a timout. 
volatile uint8_t busTimeout = 0;
volatile uint8_t hostTimeout = 0;

//set a flag if timeout
void BusTimeout(void)
{
  busTimeout = 1;
}

//set a flag if timeout
void HostTimeout(void)
{
  hostTimeout = 1;
}

void InitLeds()
{
  LED_ERROR_DDR     |= _BV(LED_ERROR_PIN);
  LED_PC_ACT_DDR    |= _BV(LED_PC_ACT_PIN);
  LED_ESTOP_DDR     |= _BV(LED_ESTOP_PIN);
  LED_GPS_DDR       |= _BV(LED_GPS_PIN);
  LED_RC_DDR        |= _BV(LED_RC_PIN);
  
  /*
  LED_ERROR_PORT    |= _BV(LED_ERROR_PIN);
  LED_PC_ACT_PORT   |= _BV(LED_PC_ACT_PIN);
  LED_ESTOP_PORT    |= _BV(LED_ESTOP_PIN);
  LED_GPS_PORT      |= _BV(LED_GPS_PIN);
  LED_RC_PORT       |= _BV(LED_RC_PIN);
  */
}


//copy the default variables into the table
int InitControlTable()
{
  int ii;
  
  //version
  ctable.version   = FIRMWARE_VERSION;

  //default ID
  ctable.id        = DEFAULT_ID;
  
  //default baud rate
  ctable.baud      = DEFAULT_BAUD_RATE;
  
  //default mode
  ctable.mode      = DEFAULT_MODE;
  
  //initialize the status
  ctable.state     = STATE_IDLE;
  ctable.currServo = 0;

  //initialize the id map to 1..32
  uint8_t * ids = ctable.idMap;
  for (ii=0; ii<MAX_NUM_SERVOS; ii++)
    *ids++ = ii+1;
  

  //initialize the default and current servo angles and velocities
  uint16_t * goalPosVals     = ctable.goalPos;
  uint16_t * goalVelVals     = ctable.goalVel;
  uint16_t * currPos         = ctable.currPos;
  
  for (ii=0; ii<MAX_NUM_SERVOS; ii++)
  {
    *goalPosVals++ = DEFAULT_SERVO_ANGLES[ii];
    *goalVelVals++ = DEFAULT_SERVO_VELS[ii];
    
    //initialize the feedback values to zero
    *currPos++ = 0;
  }
  
  //initialize the rpy values
  ctable.rpy[0] = 0;
  ctable.rpy[1] = 0;
  ctable.rpy[2] = 0;
  
  
  //initialze the digital input values
  for (ii=0; ii<NUM_DIGITAL_INPUTS; ii++)
    ctable.digitalIn[ii] = 0;
  
  //initialize the counters
  ctable.currPosCntr = 0;
  ctable.adcCntr     = 0;

  return 0;
}


void init(void)
{
  InitControlTable();

  InitLeds();
 
  uart0_init();
  uart0_setbaud(HOST_BAUD_RATE);

  rs485_init();
  rs485_setbaud(BUS_BAUD_RATE);
  
  timer1_init();
  timer1_set_overflow_callback(BusTimeout);
  
  timer4_init();
  timer4_set_overflow_callback(HostTimeout);
  
  adc_init();
  
  ResetImu();
  
  //initialize the packet data structures
  DynamixelPacketInit(&hostPacketIn);
  DynamixelPacketInit(&busPacketIn);

  sei();
}


//Send data in DynamixelPacket back to host
int HostSendPacket(uint8_t id, uint8_t type, uint8_t * buf, uint8_t size)
{
  if (size > 254)
    return -1;

  uint8_t size2 = size+2;
  uint8_t ii;
  uint8_t checksum=0;

  uart0_putchar(0xFF);   //two header bytes
  uart0_putchar(0xFF);
  uart0_putchar(id);
  uart0_putchar(size2);  //length
  uart0_putchar(type);
  
  checksum += id + size2 + type;
  
  //payload
  for (ii=0; ii<size; ii++)
  {
    uart0_putchar(*buf);
    checksum += *buf++;
  }
  
  uart0_putchar(~checksum);
  
  return 0;
}

//Send already stuffed DynamixelPacket to the PC
int HostSendRawPacket(DynamixelPacket * packet)
{
  uint8_t * buf = packet->buffer;
  uint8_t size  = packet->lenExpected;

  uint8_t ii;
  
  for (ii=0; ii<size; ii++)
    uart0_putchar(*buf++);
    
  return 0;
}

//Send data in DynamixelPacket to rs485 bus
int BusSendPacket(uint8_t id, uint8_t type, uint8_t * buf, uint8_t size)
{
  if (size > 254)
    return -1;

  uint8_t size2 = size+2;
  uint8_t ii;
  uint8_t checksum=0;

  rs485_putchar(0xFF);   //two header bytes
  rs485_putchar(0xFF);
  rs485_putchar(id);
  rs485_putchar(size2);  //length
  rs485_putchar(type);
  
  checksum += id + size2 + type;
  
  //payload
  for (ii=0; ii<size; ii++)
  {
    rs485_putchar(*buf);
    checksum += *buf++;
  }
  
  rs485_putchar(~checksum);
  
  return 0;
}

//Send already stuffed DynamixelPacket to rs485 bus
int BusSendRawPacket(DynamixelPacket * packet)
{
  uint8_t * buf = packet->buffer;
  uint8_t size  = packet->lenExpected;
  uint8_t ii;
  
  for (ii=0; ii<size; ii++)
    rs485_putchar(*buf++);
    
  return 0;
}


int SyncWrite()
{
  static uint8_t cmd[256];
  int ii;
  uint8_t * cmdPtr = cmd;
  
  uint8_t nBytesPerServo;
  uint8_t startAddress = 0;
  uint8_t payloadSize  = 0;
  
  uint8_t sendPosition = 0;
  uint8_t sendVelocity = 0;
  
  //check if we need to do the sync write at all
  if (!(ctable.mode & SYNC_WRITE_MASK))
    return 0;
  
  if (ctable.mode & _BV(MODE_BIT_SYNC_WRITE_VELOCITY))
  {
    sendVelocity = 1;
    startAddress = 32;
  }
  
  if (ctable.mode & _BV(MODE_BIT_SYNC_WRITE_POSITION))
  {
    sendPosition = 1;
    startAddress = 30;
  }
    
  nBytesPerServo = 2 * (sendPosition + sendVelocity);
  
  //fill the first two bytes of the sync-write packet with address and nBytes per serov
  *cmdPtr++      = startAddress;
  *cmdPtr++      = nBytesPerServo;
  payloadSize    = 2; //initialize payload size to 2
  
  uint8_t * ids          = ctable.idMap;
  uint16_t * desAngles   = ctable.goalPos;
  uint16_t * desVels     = ctable.goalVel;
  
  nBytesPerServo++;  //add one and use for incrementing payload size
  
  for (ii=0; ii<MAX_NUM_SERVOS; ii++)
  {
    //see if we are skipping this id
    if (*ids == SKIP_ID)
      continue;
  
    *cmdPtr++ = *ids++;
    
    if (sendPosition)
    {
      memcpy(cmdPtr,desAngles,sizeof(uint16_t));
      cmdPtr+=2;
      desAngles++;
    }
    
    if (sendVelocity)
    {
      memcpy(cmdPtr,desVels,sizeof(uint16_t));
      cmdPtr+=2;
      desVels++;
    }
   
    payloadSize+= nBytesPerServo;
  }
  
  BusSendPacket(SYNC_WRITE_ID,INSTRUCTION_SYNC_WRITE, cmd, payloadSize);

  return 0;
}

//process an incoming Dynamixel packet from host
int ProcessHostPacket(DynamixelPacket * packet)
{
  uint8_t id          = DynamixelPacketGetId(packet);
  uint8_t type        = DynamixelPacketGetType(packet);
  uint8_t size        = DynamixelPacketGetSize(packet);
  uint8_t * params    = DynamixelPacketGetData(packet);        
  
  uint16_t endOffset;
  uint8_t nRead;
  
  
  //see if the command is addressed to this device
  if (id == ctable.id)
  {
      switch (type)
      {
        case INSTRUCTION_READ_DATA:
        
          endOffset  = params[0];              //start address
          endOffset += params[1];              //how much to read
        
          if (endOffset > CONTROL_TABLE_SIZE)  //out of bounds
          {
            HostSendPacket(ctable.id,_BV(ERROR_BIT_INSTRUCTION), NULL, 0);
            break;
          }
        
          //send the response to the host
          HostSendPacket(ctable.id,NO_ERROR,&(ctablePtr[params[0]]), params[1]);
          break;
          
        case INSTRUCTION_WRITE_DATA:
          
          nRead = (size-3);                    //number of bytes to read
          endOffset  = params[0];              //start address
          endOffset += nRead;                  //size = N+3
        
          if (endOffset > CONTROL_TABLE_SIZE)  //out of bounds
          {
            HostSendPacket(ctable.id,_BV(ERROR_BIT_INSTRUCTION), NULL, 0);
            break;
          }
          
          //write data to the control table
          memcpy(&(ctablePtr[params[0]]),params+1,nRead);
          
          //send back confirmation
          HostSendPacket(ctable.id,NO_ERROR,NULL, 0);
          
          break;
            
        //don't know what to do with these yet
        case INSTRUCTION_PING:
        case INSTRUCTION_REG_WRITE:
        case INSTRUCTION_ACTION:
        case INSTRUCTION_RESET:
        case INSTRUCTION_SYNC_WRITE:
        default:
          HostSendPacket(ctable.id,_BV(ERROR_BIT_INSTRUCTION), NULL, 0);
          break;
      }
  }
  else
  {
    //dont pass through packets unless in manual mode
    if (ctable.mode == MODE_MANUAL)
    {
      //send the packet to rs485 bus
      BusSendRawPacket(packet);
    }
    else 
    {
      //respond with negative status
      HostSendPacket(ctable.id,_BV(ERROR_BIT_INVALID_MODE), NULL, 0);
    }
  }

  return 0;
}

//process an incoming Dynamixel packet from rs485 bus
int ProcessBusPacket(DynamixelPacket * packet)
{
   
  return 0;
}

//process fresh ADC data
int ProcessAdcData()
{

  return 0;
}

int main(void)
{
  int c; //make sure that this is int (16 bits), not char!!!
         //otherwise, EOF, which is -1, won't be interpreted correctly
  int ret;
  
  uint8_t cmd[16];
  
  //unsigned long count = 0;
  
  init();

  while (1) 
  {
    ret = -1;
  
    //get all the buffered characters from uart0. Read until all buffered chars are read
    //or a complete packet has been received
    c = uart0_getchar();
    while( c != EOF)
    {
      TCNT4 = 0;
      busTimeout=0;
      
      //returns positive when complete packet has been received
      ret = DynamixelPacketProcessChar(c,&hostPacketIn);
      if (ret > 0)
        break;
        
      c = uart0_getchar();
    }
    
    if (ret > 0)
      ProcessHostPacket(&hostPacketIn);


    //get all the buffered characters from rs485 bus. Read until all buffered chars are read
    //or a complete packet has been received
    
    ret = -1;
    c = rs485_getchar();
    while( c != EOF)
    {
      //reset the timeout counter
      TCNT1 = 0;
      busTimeout = 0;
    
      //returns positive when complete packet has been received
      ret = DynamixelPacketProcessChar(c,&busPacketIn);
      if (ret > 0)
        break;
        
      c = rs485_getchar();
    }
    
    
    if (ret > 0)
    {
      //if in manual mode, just send the packet to host
      if (ctable.mode == MODE_MANUAL)
      {
        //HostSendRawPacket(&busPacketIn);
        
        //reset the state just in case
        ctable.state     = STATE_IDLE;
        ctable.currServo = 0;
      }
      
      else if (ctable.state == STATE_WAITING_FOR_FEEDBACK_RESPONSE)
      {
        
        //make sure the response came back from the correct servo id
        if (DynamixelPacketGetId(&busPacketIn) != 
            ctable.idMap[ctable.currServo])
          continue;
          
        //check the error code
        if (DynamixelPacketGetType(&busPacketIn) != NO_ERROR)
          continue;
        
        
        ctable.currPos[ctable.currServo] = *(uint16_t*)(DynamixelPacketGetData(&busPacketIn));
        ctable.state = STATE_IDLE;
      }
    }
    
    //should happen after 4ms of no activity
    if (busTimeout)
    {
      ctable.state = STATE_IDLE;
      busTimeout = 0;
      TCNT1=0;
      DynamixelPacketInit(&busPacketIn);
    }
    
    //should happen after 32ms of no activity
    if (hostTimeout)
    {
      hostTimeout = 0;
      TCNT4=0;
      DynamixelPacketInit(&hostPacketIn);
    }
    
    
    
    //send out data to servos if necessary
    if ((ctable.mode != MODE_MANUAL) && (ctable.state == STATE_IDLE))
    {
      //increment servo counter. N'th iteration is reserved for sync write
      ctable.currServo++;
      if (ctable.currServo >= (MAX_NUM_SERVOS+1))
        ctable.currServo = 0;
      
      
      //time to do sync write
      if (ctable.currServo == MAX_NUM_SERVOS)
      {
        //if the sync write mode bit is set, perform sync write and wait for timer1 to timeout
        //and start next cycle of feedback queries
        if (ctable.mode & SYNC_WRITE_MASK)
        {
          SyncWrite();
          ctable.state = STATE_AFTER_SYNC_WRITE_PAUSE;
        }
      }
      else if ( (ctable.currServo != SKIP_ID) && (ctable.mode & FEEDBACK_READ_MASK) )
      {
          cmd[0] = SERVO_FEEDBACK_OFFSET;  //start address is position
          cmd[1] = 2;                      //request position and velocity
          
          BusSendPacket(ctable.idMap[ctable.currServo],INSTRUCTION_READ_DATA,cmd,2);
                        
          ctable.state = STATE_WAITING_FOR_FEEDBACK_RESPONSE;
      }
    }
      
    
    //check to see if we got full set of adc values
    //if the data is ready, it will be copied to the provided pointer
    cli();   //disable interrupts to prevent race conditions while copying, 
             //since the interrupt-based ADC cycle will write asynchronously
    ret = adc_get_data(ctable.adcVals);
    sei();   //re-enable interrupts
    
    if (ret > 0)
      ProcessImuReadings(ctable.adcVals,ctable.rpy);
      
      
    if (PINB & _BV(PB4))
    {
      //if pin high, the button is not pressed
      LED_ESTOP_PORT    &= ~(_BV(LED_ESTOP_PIN));
      ctable.digitalIn[0] = 0;
    }
    else
    { 
      //if pin is low, the button is pressed
      LED_ESTOP_PORT    |= _BV(LED_ESTOP_PIN);
      ctable.digitalIn[0] = 1;
    }
      
  }

  return 0;
}
