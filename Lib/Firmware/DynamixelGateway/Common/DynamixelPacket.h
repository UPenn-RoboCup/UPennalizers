// Packet buffer for Dynamixel-type packets.
// packet format (from Dynamixel manual:
// http://www.crustcrawler.com/motors/RX28/docs/RX28_Manual.pdf )
// [OxFF][0xFF][ID][LENGTH][INSTRUCTION][PARAMETER1]..[PARAMETERN][CHECKSUM]
// CHECKSUM = ~ ( ID + Length + Instruction + Parameter1 + ... Parameter N )
//
// This code should work both on Atmel (using avr-gcc) and any linux platform
//
// Alex Kushleyev, Upenn, akushley@seas.upenn.edu

#ifndef DYNAMIXEL_PACKET_H
#define DYNAMIXEL_PACKET_H

#include <stdio.h>
#include <stdint.h>

#define DYNAMIXEL_PACKET_HEADER 0xFF
#define DYNAMIXEL_PACKET_OVERHEAD 6
#define DYNAMIXEL_PACKET_MIN_SIZE DYNAMIXEL_PACKET_OVERHEAD
#define DYNAMIXEL_PACKET_MAX_SIZE 250
#define DYNAMIXEL_PACKET_MAX_PAYLOAD_SIZE (DYNAMIXEL_PACKET_MAX_SIZE-DYNAMIXEL_PACKET_MIN_SIZE)

enum { DYNAMIXEL_PACKET_POS_HEADER1 = 0,
       DYNAMIXEL_PACKET_POS_HEADER2,
       DYNAMIXEL_PACKET_POS_ID,
       DYNAMIXEL_PACKET_POS_SIZE,
       DYNAMIXEL_PACKET_POS_TYPE,
       DYNAMIXEL_PACKET_POS_DATA };
       
       
//buffer packet definition
typedef struct
{
  uint8_t buffer[DYNAMIXEL_PACKET_MAX_SIZE];  //buffer for data
  uint8_t lenReceived; //number of chars received so far
  uint8_t lenExpected; //expected number of chars based on header
  uint8_t * bp;        //pointer to the next write position in the buffer
} DynamixelPacket;


//calculate the checksum
uint8_t   DynamixelPacketChecksum(uint8_t * buf, uint8_t len);

//initialze the fields in the dynamixel packet buffer
void      DynamixelPacketInit(DynamixelPacket * packet);

//feed one char and see if we have accumulated a complete packet
int16_t   DynamixelPacketProcessChar(uint8_t c, DynamixelPacket * packet);

//get id of the sender
uint8_t   DynamixelPacketGetId(DynamixelPacket * packet);
uint8_t   DynamixelPacketRawGetId(uint8_t * packet);

//get size of the packet (as it appears in dynamixel packet)
uint8_t   DynamixelPacketGetSize(DynamixelPacket * packet);
uint8_t   DynamixelPacketRawGetSize(uint8_t * packet);

//get a pointer to the packet type
uint8_t   DynamixelPacketGetType(DynamixelPacket * packet);
uint8_t   DynamixelPacketRawGetType(uint8_t * packet);

//get a pointer to the packet payload
uint8_t * DynamixelPacketGetData(DynamixelPacket * packet);
uint8_t * DynamixelPacketRawGetData(uint8_t * packet);

//wrap arbitrary data into the Dynamixel packet format
int16_t DynamixelPacketWrapData(uint8_t id, uint8_t type,
                                uint8_t * data, uint16_t dataSize, 
                                uint8_t * outBuf, uint16_t outSize);

                                
int16_t DynamixelPacketVerifyRaw(uint8_t * buf, uint8_t size);

#endif //DYNAMIXEL_PACKET_H

