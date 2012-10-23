#include "DynamixelGateway.hh"


DynamixelGateway::DynamixelGateway()
{
  this->sd         = new SerialDevice();
  this->dpacket    = new DynamixelPacket();
  this->receiveBuf = new uint8_t[RECEIVE_BUF_SIZE];
  this->sendBuf    = new uint8_t[SEND_BUF_SIZE];
  this->cmdBuf     = new uint8_t[CMD_BUF_SIZE];
  this->connected  = false;
  this->numJoints  = MAX_NUM_SERVOS;
  this->timeoutUs  = DEF_CHAR_TIMEOUT_US;
  this->id         = DEFAULT_ID;
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


int DynamixelGateway::SetNumJoints(int n)
{
  if ( (n<0) || (n>=MAX_NUM_SERVOS) )
  {
    printf("bad number of joints : %d\n",n);
    return -1;
  }
  
  this->numJoints = n;
  
  return 0;
}


//write the servo ids to microcontroller
//make sure to have proper number of servos set
int DynamixelGateway::SetIDs(double * ids)
{
  CHECK_CONNECTION;

  uint8_t cmd[128];
  uint8_t size = 1;
  cmd[0] = ID_MAP_OFFSET;
  
  uint8_t * cmdPtr = &(cmd[1]);
  
  for (int ii=0; ii<this->numJoints; ii++)
  {
    //check the ids
    if ( (*ids<0) || (*ids>255))
    {
      printf("bad id #%d : %f\n",ii,*ids);
      return -1;
    }
  
    *cmdPtr++ = (uint8_t)*ids++;
    size++;
  }
  
  if (this->SendWriteDataAndGetConfirm(cmd, size))
  {
    printf("could not set ids\n");
    return -1;
  }

  return 0;
}

int DynamixelGateway::SetMode(uint8_t mode)
{
  CHECK_CONNECTION;

  uint8_t cmd[2];
  cmd[0] = MODE_OFFSET;
  cmd[1] = mode;

  if (SendWriteDataAndGetConfirm(cmd, 2))
  {
    printf("could not set mode\n");
    return -1;
  }

  return 0;
}

int DynamixelGateway::SetManual()
{
  uint8_t mode = 0;
  return this->SetMode(mode);
}

int DynamixelGateway::SetAutoRead()
{
  uint8_t mode = 1<<MODE_BIT_POSITION_FEEDBACK;
  return this->SetMode(mode);
}

int DynamixelGateway::SetAutoReadWrite()
{
  uint8_t mode = 1<<MODE_BIT_POSITION_FEEDBACK | 1<<MODE_BIT_SYNC_WRITE_POSITION | 1<<MODE_BIT_SYNC_WRITE_VELOCITY;
  return this->SetMode(mode);
}

int DynamixelGateway::SetAutoWrite()
{
  uint8_t mode = 1<<MODE_BIT_SYNC_WRITE_POSITION | 1<<MODE_BIT_SYNC_WRITE_VELOCITY;
  return this->SetMode(mode);
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
  for(int i=0;i<4;i++)
    this->receiveBuf[i]=0;

  //read off the packet header
  int nRead = this->sd->ReadChars((char*)this->receiveBuf,4,DEF_CHAR_TIMEOUT_US);
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

int DynamixelGateway::SendWriteData(uint8_t * data, uint8_t size)
{
  CHECK_CONNECTION;

  int outSize = DynamixelPacketWrapData(this->id,INSTRUCTION_WRITE_DATA,
                                data,size,this->sendBuf,SEND_BUF_SIZE);
                                
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

int DynamixelGateway::ReceiveWriteConfirmation()
{
  CHECK_CONNECTION;

  if (this->ReceivePacket() > 0)
  {
    //check the id
    if (DynamixelPacketGetId(this->dpacket) != this->id)
    {
      printf("id in response does not match: %02x\n",
                    DynamixelPacketGetId(this->dpacket));
      return -1;
    }
    
    //check the error code
    if (DynamixelPacketGetType(this->dpacket) != 0)
    {
      printf("response error : %02x\n",
                    DynamixelPacketGetType(this->dpacket));
      return -1;
    }
    return 0;
  }
  else
  {
    printf("no confirmation (timeout?)\n");
    return -1;
  }
}


int DynamixelGateway::SendWriteDataAndGetConfirm(uint8_t * data, uint8_t size)
{
  CHECK_CONNECTION;

  if (this->SendWriteData(data, size))
  {
    printf("could not write data\n");
    return -1;
  }

  if (ReceiveWriteConfirmation())
  {
    printf("could not get confirmation\n");
    return -1;
  }

  return 0;
}

int DynamixelGateway::SetJointAngles(double * jointAngles)
{
  CHECK_CONNECTION;

  uint8_t cmd[128];
  uint8_t size =1;
  cmd[0] = GOAL_POSITION_VALS_OFFSET;

  uint16_t * angles = (uint16_t *)&(cmd[1]);

  for (int ii=0; ii< this->numJoints; ii++)
  {
    angles[ii] = jointAngles[ii];
    size+=2;
  }

  if (this->SendWriteDataAndGetConfirm(cmd, size))
  {
    printf("could not set joint angles\n");
    return -1;
  }

  return 0;
}

int DynamixelGateway::SetJointVelocities(double * jointVels)
{
  CHECK_CONNECTION;

  uint8_t cmd[128];
  uint8_t size =1;
  cmd[0] = GOAL_VELOCITY_VALS_OFFSET;

  uint16_t * vels = (uint16_t *)&(cmd[1]);

  for (int ii=0; ii< this->numJoints; ii++)
  {
    vels[ii] = jointVels[ii];
    size+=2;
  }

  if (this->SendWriteDataAndGetConfirm(cmd, size))
  {
    printf("could not set joint velocities\n");
    return -1;
  }

  return 0;
}


int DynamixelGateway::GetJointAngles(double * jointAngles)
{
  CHECK_CONNECTION;

  int readOffset = CURR_POSITION_VALS_OFFSET ;
  int numRead    = this->numJoints*2;

  if (this->SendReadRequest(readOffset, numRead))
  {
    printf("could not GetJointAngles (error sending data)\n");
    return -1;
  }

  if (this->ReceivePacket() > 0)
  {
    int error = DynamixelPacketGetType(this->dpacket);
    if (error == 0)
    {
      uint16_t * data = (uint16_t*)DynamixelPacketGetData(this->dpacket);

      for (int ii=0; ii<this->numJoints; ii++)
        jointAngles[ii] = data[ii];

      return 0;
    }
    else
    {
      printf("could not GetJointAngles error code = %d\n",error);
      return -1;
    }
  }
  else
  {
    printf("could not GetJointAngles (no response)\n");
    return -1;
  }
}

int DynamixelGateway::GetAdc(double * adcVals)
{
  CHECK_CONNECTION;

  int readOffset = ADC_VALS_OFFSET;
  int numRead    = NUM_ADC_CHANNELS*2;

  if (this->SendReadRequest(readOffset, numRead))
  {
    printf("could not GetAdc (error sending data)\n");
    return -1;
  }

  if (this->ReceivePacket() > 0)
  {
    int error = DynamixelPacketGetType(this->dpacket);
    if (error == 0)
    {
      uint16_t * data = (uint16_t*)DynamixelPacketGetData(this->dpacket);

      for (int ii=0; ii<NUM_ADC_CHANNELS; ii++)
        adcVals[ii] = data[ii];

      return 0;
    }
    else
    {
      printf("could not GetAdc error code = %d\n",error);
      return -1;
    }
  }
  else
  {
    printf("could not GetAdc (no response)\n");
    return -1;
  }
}


int DynamixelGateway::ReadBlock(uint8_t * data, uint8_t offset, uint8_t size)
{
  CHECK_CONNECTION;

  if (this->SendReadRequest(offset, size))
  {
    printf("could not ReadBlock (error sending data)\n");
    return -1;
  }

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
      printf("could not ReadBlock error code = %d\n",error);
      return -1;
    }
  }
  else
  {
    printf("could not ReadBlock (no response)\n");
    return -1;
  }
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

int DynamixelGateway::SyncWrite(uint8_t * packet, uint8_t size)
{
  CHECK_CONNECTION;

  if (this->sd->WriteChars((const char*)packet,size) == size)
    return 0;
  else
  {
    printf("could not SyncWrite (error writing data)\n");
    return -1;
  }
}


