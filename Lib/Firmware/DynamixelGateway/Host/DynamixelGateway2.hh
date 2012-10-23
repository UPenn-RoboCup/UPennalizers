#ifndef DYNAMIXEL_GATEWAY2_HH
#define DYNAMIXEL_GATEWAY2_HH

#include "SerialDevice.hh"
#include "DynamixelPacket.h"
#include <stdint.h>

#define DEF_CHAR_TIMEOUT_US 20000
#define RECEIVE_BUF_SIZE 512
#define SEND_BUF_SIZE 512
#define CMD_BUF_SIZE 512

#define CHECK_CONNECTION { if (!this->connected) {printf("not connected to device\n"); return -1; } } 


class DynamixelGateway
{
  public: DynamixelGateway();
  public: ~DynamixelGateway();
  
  
  //connect to the serial port and verify whether
  //the gateway is present
  public: int Connect(char * dev, char * baud);
  public: int Connect(char * dev, int baud);
  
  //disconnect from serial port
  public: int Disconnect();

  //use this for doing sync write to motors that does not produce a resonse
  public: int Write(uint8_t * packet, uint8_t size);
  
  public: int Read(uint8_t * data);
  
  private: int ReceivePacket();
  
  public: int ReadTable(uint8_t * data);
  private: int SendReadRequest(uint8_t readOffset, uint8_t size);
    
  private: uint8_t           id;
  private: SerialDevice     *sd;
  private: bool              connected;
  private: int               numJoints;
  private: int               timeoutUs;
  private: DynamixelPacket  *dpacket;
  private: uint8_t          *receiveBuf;
  private: uint8_t          *sendBuf;
  private: uint8_t          *cmdBuf;
  

};

#endif //DYNAMIXEL_GATEWAY_HH
