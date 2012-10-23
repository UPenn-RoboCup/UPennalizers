#include "DynamixelPacket.h"
#include "SerialDevice.hh"
#include "Timer.hh"
#include "ControlTable.h"
#include <stdint.h>

#define GATEWAY_ID 128

SerialDevice sd;
DynamixelPacket dpacket;

const int outBufSize = 256;
uint8_t rawPacketOut[outBufSize];

int ReadPacket(DynamixelPacket * dpacket)
{
  char c;
  int nChars;
  int ret;
  
  nChars = sd.ReadChars(&c,1);
  while(nChars>0)
  {
    if (nChars > 0)
    {
      //printf("%02x ",(uint8_t)c);
      ret = DynamixelPacketProcessChar(c,dpacket);
      if (ret > 0)
      {
        //printf("got response!\n");
        return 0;
      }
    }
    nChars = sd.ReadChars(&c,1);
  }

  return -1;
}


int ReadADC(int num)
{
  int readOffset = ADC_VALS_OFFSET ;
  int numRead = num *2;
  
  uint8_t cmd[2] = {readOffset,numRead};
  int outSize = DynamixelPacketWrapData(GATEWAY_ID,INSTRUCTION_READ_DATA,cmd,2,rawPacketOut,outBufSize);

  if (outSize < 0)
  {
    printf("could not create outgoing packet\n");
    return -1;
  }

  if (sd.WriteChars((const char*)rawPacketOut,outSize) != outSize)
  {
    printf("could not write data to serial port \n");
    return -1;
  }
  
  if (ReadPacket(&dpacket) == 0)
  {
    uint16_t * adcData = (uint16_t*)DynamixelPacketGetData(&dpacket);
    printf("adc data = ");  
    for (int ii=0; ii<num; ii++)
      printf("%d ",adcData[ii]);
    printf("\n");
    return 0;
  }
  else
    return -1;
}

int ReadFeedback(int num)
{
  int readOffset = CURR_POSITION_VALS_OFFSET ;
  int numRead = num*2;
  
  uint8_t cmd[2] = {readOffset,numRead};
  int outSize = DynamixelPacketWrapData(GATEWAY_ID,INSTRUCTION_READ_DATA,cmd,2,rawPacketOut,outBufSize);

  if (outSize < 0)
  {
    printf("could not create outgoing packet\n");
    return -1;
  }

  if (sd.WriteChars((const char*)rawPacketOut,outSize) != outSize)
  {
    printf("could not write data to serial port \n");
    return -1;
  }
  
  if (ReadPacket(&dpacket) == 0)
  {
    uint16_t * data = (uint16_t*)DynamixelPacketGetData(&dpacket);
    printf("angle data = ");  
    for (int ii=0; ii<num; ii++)
      printf("%d ",data[ii]);
    printf("\n");
    return 0;
  }
  else
    return -1;
}

int WriteAngle(uint16_t angle)
{
  int writeOffset = GOAL_POSITION_VALS_OFFSET;
  uint8_t cmd[128];

  cmd[0] = writeOffset;

  uint16_t * angles = (uint16_t *)&(cmd[1]);

  for (int ii=0; ii< 2; ii++)
  {
    memcpy(angles++,&angle,sizeof(uint16_t));
  }

  int outSize = DynamixelPacketWrapData(GATEWAY_ID,INSTRUCTION_WRITE_DATA,cmd,1+4,rawPacketOut,outBufSize);

  if (outSize < 0)
  {
    printf("could not create outgoing packet\n");
    return -1;
  }

  if (sd.WriteChars((const char*)rawPacketOut,outSize) != outSize)
  {
    printf("could not write data to serial port \n");
    return -1;
  }
  
  if (ReadPacket(&dpacket) == 0)
  {
    uint8_t response = DynamixelPacketGetType(&dpacket);
    if (response == 0 )
    {
      //printf("angle successfully set\n");
      return 0;
    }
    else
    {
      printf("could not set angle\n");
      return -1;
    }
  }
  else
  {
    printf("could not get response\n");
    return -1;
  }

}

int ReadTable()
{
  int readOffset = 0 ;
  int numRead = 100;
  
  uint8_t cmd[2] = {readOffset,numRead};
  int outSize = DynamixelPacketWrapData(GATEWAY_ID,INSTRUCTION_READ_DATA,cmd,2,rawPacketOut,outBufSize);

  if (outSize < 0)
  {
    printf("could not create outgoing packet\n");
    return -1;
  }

  if (sd.WriteChars((const char*)rawPacketOut,outSize) != outSize)
  {
    printf("could not write data to serial port \n");
    return -1;
  }
  
  if (ReadPacket(&dpacket) == 0)
  {
    uint8_t * data = DynamixelPacketGetData(&dpacket);
    printf("table data = ");  
    for (int ii=0; ii<numRead; ii++)
    {
      if (ii%8 == 0)
        printf("\n");
      printf("%02x ",data[ii]);
      
    }
    printf("\n");
    return 0;
  }
  else
    return -1;
}




int main(int argc, char * argv[])
{
  char * dev  = (char*)"/dev/ttyUSB0";
  char * baud = (char*)"1000000"; 


  if (argc == 2)
    dev = argv[1];

  if (argc == 3)
    baud = argv[2];

  printf("control table size = %d\n",(int)CONTROL_TABLE_SIZE);
  printf("goal vals offset = %d\n",(int)GOAL_POSITION_VALS_OFFSET);  

  if (sd.Connect(dev,baud))
  {
    printf("could not connec to device %s at baud rate %s\n",dev,baud);
    return -1;
  }

  DynamixelPacketInit(&dpacket);

  int writeOffset = MODE_OFFSET;
  int mode = 1<<MODE_BIT_POSITION_FEEDBACK; //  | 1<<MODE_BIT_SYNC_WRITE_POSITION;
  uint8_t cmd[2];
  cmd[0] = writeOffset;
  cmd[1] = mode;

  printf("write offset =%d\n",writeOffset);

  int outSize = DynamixelPacketWrapData(GATEWAY_ID,INSTRUCTION_WRITE_DATA,cmd,2,rawPacketOut,outBufSize);

  if (outSize < 0)
  {
    printf("could not create outgoing packet\n");
    return -1;
  }

  if (sd.WriteChars((const char*)rawPacketOut,outSize) != outSize)
  {
    printf("could not write data to serial port \n");
    return -1;
  }

  if (!ReadPacket(&dpacket))
    printf("set mode to automatic!\n");
  else
  {
    printf("could not set mode to automatic!\n");
    return -1;
  }

  int cntr = 0;

  uint16_t angle = 0;


  Upenn::Timer timer0;  



  while(1)
  {
    //ReadADC(6);
    //timer0.Tic();
    ReadFeedback(23);
    //timer0.Toc(true);
    //ReadTable();

    //return 0;
/*
    WriteAngle(angle);
    angle = angle+2;

    if (angle>1022)
      angle = 0;
*/
    usleep(5000);
    printf("%d ",cntr++); fflush(stdout);
  }


  

  return 0;
}
