#ifndef DYNAMIXEL_GATEWAY_HH
#define DYNAMIXEL_GATEWAY_HH

#include "SerialDevice.hh"
#include "DynamixelPacket.h"
#include "ControlTable.h"
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
  

  //set the number of servos
  public: int SetNumJoints(int n);

  //set to manual mode
  public: int SetManual();

  //set to automatic feedback reading mode (no writing desired values to servos)
  public: int SetAutoRead();

  //set to automatic feedback and sync write mode (feedback and setting position + velocity values)
  public: int SetAutoReadWrite();

  //set to automatic writing only (position and velocity) via sync write
  public: int SetAutoWrite();

  //set any mode
  public: int SetMode(uint8_t mode);
  
  public: int SetIDs(double * ids);
  
  
  //set joint angles (double vals which are storing uint16 vals)
  public: int SetJointAngles(double * angles);
  
  //set joint velocities (double vals which are storing uint16 vals)
  public: int SetJointVelocities(double * vels);

  //read a block of memory
  public: int ReadBlock(uint8_t * data, uint8_t offset, uint8_t size);

  //get the latest joint angles from the control table
  public: int GetJointAngles(double * jointAngles);
  
  //use this for doing sync write to motors that does not produce a resonse
  public: int SyncWrite(uint8_t * packet, uint8_t size);

  public: int GetAdc(double * adcVals);
  
  public: int ReadTable(uint8_t * data);
  
  private: int ReceivePacket();
  private: int SendWriteData(uint8_t * data, uint8_t size);
  private: int SendWriteDataAndGetConfirm(uint8_t * data, uint8_t size);
  private: int SendReadRequest(uint8_t readOffset, uint8_t size);
  private: int ReceiveWriteConfirmation();

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
