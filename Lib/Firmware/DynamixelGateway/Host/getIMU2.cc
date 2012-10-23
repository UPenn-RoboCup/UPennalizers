#include "../../Common/dynamixel_instruction.h"

#include "DynamixelGateway2.hh"
#include "../../Common/ctable.h"
#include <iostream>
#include "Timer.hh"

void debugpacket(std::string frame){

    printf("Dynamixel Frame generated is ");
    for(int i=0;i<frame.size();i++)
        printf("%d ", (uint8_t) *(frame.data()+i));
    printf("\n");
}

int main(int argc, char * argv[])
{
  char * dev  = (char*)"/dev/ttyUSB0";
  char * baud = (char*)"1000000"; 


  if (argc == 2)
    dev = argv[1];

  if (argc == 3)
    baud = argv[2];

  DynamixelGateway dgateway;
  if (dgateway.Connect(dev,baud))
  {
    printf("could not connect to device %s baud %s\n",dev,baud);
    return -1;
  }

	/*
  uint8_t table[256];

  int tableSize = dgateway.ReadTable(table);

  if ( tableSize < 0)
  {
    printf("could not read table\n");
    return -1;
  }

  printf("table size = %d\n",tableSize);

  for (int ii=0; ii<tableSize; ii++)
  {
    if (ii%8 == 0)
      printf("\n");
    printf("%02x ",table[ii]);
    
  }
  printf("\n");


  //set auto mode
  if (dgateway.SetAutoRead())
  {
    printf("could not set auto mode\n");
    return -1;
  }

	*/
  //get angles
  const int nServos = 23;
  double * angles = new double[nServos];
  double * desAngles = new double[nServos];

  double angle =512;

  Upenn::Timer timer0;
  
  uint16_t ADC [6];
  
  ControlTable sct1;

	printf("ctable size =%d nbyte =%d\n", CONTROL_TABLE_SIZE, CONTROL_TABLE_SIZE- OFFSET_BUTTON);
  std::string frame, frame_battery;      
  frame = ReadDataFrame(DEFAULT_ID, 0, CONTROL_TABLE_SIZE);
  debugpacket(frame);
  if (dgateway.Write((uint8_t *)frame.data(), frame.size()))
		printf("naoChestThread: could not write\n");
	
	usleep(100);

  if (dgateway.Read((uint8_t *)&sct1)) {
      printf("naoChestThread: could not read\n");
      //sd_reconnect();
    }

  SubControlTable sct;
  frame = ReadDataFrame(DEFAULT_ID, OFFSET_BUTTON, OFFSET_LENREAD - OFFSET_BUTTON + 3*NUM_SERVO);
  
  debugpacket(frame);
  
 
  uint8_t  battery[1];

  int ret, ID = 1;
  while(1){
  
  frame_battery = ReadDataFrame(ID, ADDR_PRESENT_VOLTAGE, 1);
  if (dgateway.Write((uint8_t *)frame_battery.data(), frame_battery.size()))
		printf("naoChestThread: could not write\n");

  if (dgateway.Read(battery)) 
      printf("naoChestThread: could not read voltage from ID = %d\n", ID);
	else
  	printf("ID = %d voltage : %d\n", ID, battery[0]/10); //voltage is 10 times the actual V

  if (++ID > 21)
  	ID = 1;  

	if (dgateway.Write((uint8_t *)frame.data(), frame.size()))
		printf("naoChestThread: could not write\n");
	
	//usleep(100);

  if (dgateway.Read((uint8_t *)&sct)) {
      printf("naoChestThread: could not read\n");
      //sd_reconnect();
    }
  else
    {
    
    printf("ctable button offset = %d\n", OFFSET_BUTTON);
    printf("ctable.button %d\n", sct.button);
    printf("ctable.input:");
    for (int i=0;i<NUM_INPUT;i++)
    	printf(" %d", sct.input[i]);
    printf("\n");
    
    printf("ctable imuAcc offset = %d\n", OFFSET_IMUACC);
    printf("ctable.imuAcc:");
    for (int i=0;i<3;i++)
    	printf(" %d", sct.imuAcc[i]);
    printf("\n");
    
    printf("ctable imuGyr offset = %d\n", OFFSET_IMUGYR);
    printf("ctable.imuGyr:");
    for (int i=0;i<3;i++)
    	printf(" %d", sct.imuGyr[i]);
    printf("\n");
    
    printf("ctable imuAngle offset = %d\n", OFFSET_IMUANGLE);
    printf("ctable.imuAngle:");
    for (int i=0;i<NUM_IMU_ANGLE;i++)
    	printf(" %d", sct.imuAngle[i]);
    printf("\n");

		/*
    printf("ctable.imuAngle uint16:");
    for (int i=0;i<NUM_IMU_ANGLE;i++)
    	printf(" %d", sct.imuAngle2[i]);
    printf("\n");*/
    
    printf("ctable addrRead offset = %d\n", OFFSET_ADDRREAD);
    printf("addrRead : %d\n", sct.addrRead);
    printf("lenRead : %d\n", sct.lenRead);

		
    printf("Position:");
    for (int i=0;i<NUM_SERVO*3;i++)
    	printf(" %d", sct.dataRead[i]);
    printf("\n\n");
    	
    usleep(5000);
  }

	}
 
 //usleep(2000);

  return 0;
}

