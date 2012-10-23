#include "DynamixelGateway2.hh"


DynamixelGateway::DynamixelGateway()
{
  this->sd         = new SerialDevice();
  this->dpacket    = new DynamixelPacket();
  this->receiveBuf = new uint8_t[RECEIVE_BUF_SIZE];
  this->sendBuf    = new uint8_t[SEND_BUF_SIZE];
  this->cmdBuf     = new uint8_t[CMD_BUF_SIZE];
  this->connected  = false;
  this->timeoutUs  = DEF_CHAR_TIMEOUT_US;
  DynamixelPacketInit(this->dpacket);
}


DynamixelGateway::~DynamixelGateway()
{
  this->Disconnect();
  
  //clean up
  if (this->sd) delete this->sd; this->sd = NULL;
  if (this->dpacket) delete this->dpacket; this->dpacket = NULL;
}

int DynamixelGateway::Connect(char * dev, char * baud)
{
  if (this->connected)
    return 0;
  
  int ret = this->sd->Connect(dev,baud);
  
  if (ret == 0)
    this->connected = true;
  
  return ret;
}

int DynamixelGateway::Connect(char * dev, int baud)
{
  if (this->connected)
    return 0;
    
  int ret = this->sd->Connect(dev,baud);
    
  if (ret == 0)
    this->connected = true;
    
  return ret;
}

int DynamixelGateway::Disconnect()
{
  if (this->sd) this->sd->Disconnect();
  this->connected = false;
  return 0;
}

//Receive a packet.
//Returns length of packet if successfully received
//Returns zero or negative otherwise
//The packet is stored in this->dpacket
int DynamixelGateway::ReceivePacket()
{
  CHECK_CONNECTION;

  int ret = -1;
  int nChars;
  
  DynamixelPacketInit(this->dpacket);


  //read off the packet header
  int nRead = this->sd->ReadChars((char*)this->receiveBuf,4,DEF_CHAR_TIMEOUT_US);
  /*printf("Packet = ");
  for (int i = 0; i< nRead ; i++)
  	printf(" %u",this->receiveBuf[i]);
  printf("\n");*/
  if (nRead != 4 || (this->receiveBuf[0] != 0xFF) || (this->receiveBuf[1] != 0xFF) )
  {
    printf("could not read packet header\n");
    return 0;
  }

  for (int ii=0; ii<4; ii++)
    DynamixelPacketProcessChar(this->receiveBuf[ii],this->dpacket);
  
  int nToRead = this->receiveBuf[3];

  while(ret < 0)
  {
    nChars = this->sd->ReadChars((char*)this->receiveBuf,
                nToRead, DEF_CHAR_TIMEOUT_US);
                
    if (nChars > 0)
    {
      //process one char at a time
      for (int ii=0; ii<nChars; ii++)
      {
        //printf("%02x ",(uint8_t)this->receiveBuf[ii]);
        ret = DynamixelPacketProcessChar(this->receiveBuf[ii],
                                         this->dpacket);
                                         
        if (ret > 0)  //got complete packet
          break;
      }
    }
    else
      break;
  }
  
  return ret;
}

int DynamixelGateway::Read(uint8_t * data)
{
	CHECK_CONNECTION;

  if (this->ReceivePacket() > 0)
  {
    int error = DynamixelPacketGetType(this->dpacket);
    if (error == 0)
    {
      //copy the payload only
      memcpy(data,DynamixelPacketGetData(this->dpacket),
                  DynamixelPacketGetSize(this->dpacket)-2);  //subtract 2 from dynamixel size

      return 0;
    }
    else
    {
      printf("could not Read error code = %d\n",error);
      return -1;
    }
  }
  else
  {
    printf("could not Read (no response)\n");
    return -1;
  }
}

int DynamixelGateway::Write(uint8_t * packet, uint8_t size)
{
  CHECK_CONNECTION;

  if (this->sd->WriteChars((const char*)packet,size) == size)
    return 0;
  else
  {
    printf("could not Write (error writing data)\n");
    return -1;
  }
}

/*
int DynamixelGateway::SendReadRequest(uint8_t readOffset, uint8_t size)
{
  CHECK_CONNECTION;

  const int cmdSize = 2;
  uint8_t cmd[cmdSize] = {readOffset,size};
  
  int outSize = DynamixelPacketWrapData(this->id,INSTRUCTION_READ_DATA,
                        cmd,cmdSize,this->sendBuf,SEND_BUF_SIZE);
                        
  if (outSize < 0)
  {
    printf("could not create outgoing packet\n");
    return -1;
  }
  
  if (this->sd->WriteChars((const char*)this->sendBuf,outSize) != outSize)
  {
    printf("could not write data to serial port \n");
    return -1;
  }

  return 0;
}

int DynamixelGateway::ReadTable(uint8_t * table)
{
  CHECK_CONNECTION;

  uint8_t readOffset = 0;
  uint8_t numRead    = CONTROL_TABLE_SIZE;
  
  if (this->SendReadRequest(readOffset, numRead))
  {
    printf("could not read full table (error sending data)\n");
    return -1;
  }
  
  if (this->ReceivePacket() > 0)
  {
    int error = DynamixelPacketGetType(this->dpacket);
    if (error == 0)
    {
      uint8_t * data = DynamixelPacketGetData(this->dpacket);

      int size = DynamixelPacketGetSize(this->dpacket)-2;
      memcpy(table,data,size);
      return size;
    }
    else
    {
      printf("could not ReadTable: error code = %d\n",error);
      return -1;
    }
  }
  else
  {
    printf("could not ReadTable (no response)\n");
    return -1;
  }
}
*/

