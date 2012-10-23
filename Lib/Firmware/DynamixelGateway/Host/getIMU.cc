#include "DynamixelGateway.hh"
#include <iostream>
#include "Timer.hh"

  typedef struct
{

  uint16_t currPos[MAX_NUM_SERVOS];       //48 bytes
  uint16_t adcVals[NUM_ADC_CHANNELS];     //16 bytes
  float rpy[3];                           //12 bytes
  uint8_t  digitalIn[NUM_DIGITAL_INPUTS]; //4 bytes

} SubControlTable;

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

  //get angles
  const int nServos = 23;
  double * angles = new double[nServos];
  double * desAngles = new double[nServos];

  double angle =512;

  Upenn::Timer timer0;
  
  uint16_t ADC [6];
  
  SubControlTable sct;
  while(1)
  {
  if (dgateway.ReadBlock((uint8_t *)&sct, CURR_POSITION_VALS_OFFSET, sizeof(SubControlTable))) 
    {
      printf("could not read block\n");
      continue;
      //return -1;
    }
else{
    printf("ADC:");
    for (int i=0;i<6;i++)
    	printf(" %d", sct.adcVals[i]);
    printf("\n");  
        
    printf("RPY:");    
   printf("rpy = %f %f %f\n", sct.rpy[0],sct.rpy[1],sct.rpy[2]);
   
    printf("Position:");
    for (int i=0;i<23;i++)
    	printf(" %d", sct.currPos[i]);
    printf("\n");
    
    printf("Digital In:");
    	printf(" %d", sct.digitalIn[0]);
    printf("\n");
    	
    usleep(5000);
  }
    for (int i=0;i<6;i++)
    	printf(" %d", sct.adcVals[i]);
    printf("\n");


    
    for (int i=0;i<23;i++)
    	printf(" %d", sct.currPos[i]);
    printf("\n");
    	
    usleep(10000);

  }

  return 0;
}

