#include "DynamixelPacket.h"

//calculate checksum using Dynamixel's formula:
//checksum = ~ (sum(byte0...byteN))
uint8_t DynamixelPacketChecksum(uint8_t * buf, uint8_t len)
{
  uint8_t ii;
  uint8_t checksum = 0;
  for (ii=0; ii<len; ii++)
    checksum += *buf++;
    
  return ~checksum;
}

//initialize the packet
void DynamixelPacketInit(DynamixelPacket * packet)
{
  packet->lenReceived = 0;
  packet->lenExpected = 0;
  packet->bp          = NULL;
}

//get the sender's id
uint8_t   DynamixelPacketGetId(DynamixelPacket * packet)
{
  return packet->buffer[DYNAMIXEL_PACKET_POS_ID];
}

uint8_t   DynamixelPacketRawGetId(uint8_t * packet)
{
  return packet[DYNAMIXEL_PACKET_POS_ID];
}

//get the packet size
uint8_t   DynamixelPacketGetSize(DynamixelPacket * packet)
{
  return packet->buffer[DYNAMIXEL_PACKET_POS_SIZE];
}

uint8_t   DynamixelPacketRawGetSize(uint8_t * packet)
{
  return packet[DYNAMIXEL_PACKET_POS_SIZE];
}

//get the packet type
uint8_t   DynamixelPacketGetType(DynamixelPacket * packet)
{
  return packet->buffer[DYNAMIXEL_PACKET_POS_TYPE];
}

uint8_t   DynamixelPacketRawGetType(uint8_t * packet)
{
  return packet[DYNAMIXEL_PACKET_POS_TYPE];
}

//get the pointer to packet's payload
uint8_t * DynamixelPacketGetData(DynamixelPacket * packet)
{
  return &(packet->buffer[DYNAMIXEL_PACKET_POS_DATA]);
}

uint8_t * DynamixelPacketRawGetData(uint8_t * packet)
{
  return &(packet[DYNAMIXEL_PACKET_POS_DATA]);
}

//feed in a character and see if we got a complete packet
int16_t   DynamixelPacketProcessChar(uint8_t c, DynamixelPacket * packet)
{
  int16_t ret = -1;
  uint8_t checksum;
    
  switch (packet->lenReceived)
  {
    case 0:
      packet->bp = packet->buffer;    //reset the pointer for storing data
      
    //fall through, since first two bytes should be 0xFF
    case 1:
      if (c != DYNAMIXEL_PACKET_HEADER)       //check the packet header (0xFF)
      {
        packet->lenReceived = 0;
        break;
      }
    
    //fall through, since we are just storing ID and length
    case 2:                           //ID
    case 3:                           //LENGTH
      packet->lenReceived++;
      *(packet->bp)++ = c;
      break;
        
    case 4:                           //by now we've got 0xFF, 0xFF, ID, LENGTH
      packet->lenExpected = packet->buffer[3] + 4;  //add 4 to get the full length
      
      //verify the expected length
      if (packet->lenExpected < DYNAMIXEL_PACKET_MIN_SIZE)
      {
        packet->lenReceived = 0;
        break;
      }
      
    //read off the rest of the packet
    default:
      packet->lenReceived++;
      *(packet->bp)++ = c;
      
      if (packet->lenReceived < packet->lenExpected)
        break;  //have not received enough yet
    
      //calculate expected checksum
      //skip first two 0xFF and the actual checksum
      checksum = DynamixelPacketChecksum(packet->buffer+2,
                                         packet->lenReceived-3);
      
      if (checksum == c)
        ret  = packet->lenReceived;
      
      //reset the counter
      packet->lenReceived = 0;
  }
  
  return ret;
}


//wrap arbitrary data into the Dynamixel packet format
int16_t DynamixelPacketWrapData(uint8_t id, uint8_t type,
                                uint8_t * data, uint16_t dataSize, 
                                uint8_t * outBuf, uint16_t outSize)
{
  uint16_t packetSize = dataSize + DYNAMIXEL_PACKET_OVERHEAD;

  //make sure enough memory is externally allocated
  if (outSize < packetSize)
    return -1;

  uint8_t ii;
  uint8_t payloadSize = dataSize+2;     //length includes packet, type and checksum
  uint8_t checksum    = 0;
  uint8_t * obuf      = outBuf;
  uint8_t * ibuf      = data;
  *obuf++             = 0xFF;           //two header bytes
  *obuf++             = 0xFF;
  *obuf++             = id;
  *obuf++             = payloadSize;
  *obuf++             = type;
  checksum           += id + payloadSize + type;
  
  //copy data and calculate the checksum
  for (ii=0; ii<dataSize; ii++)
  {
    *obuf++ = *ibuf;
    checksum += *ibuf++;
  }
  
  *obuf = ~checksum;
  
  return packetSize;
}

//verify the full packet
int16_t DynamixelPacketVerifyRaw(uint8_t * buf, uint8_t size)
{
  //TODO: implement

  return -1;
}

