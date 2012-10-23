#include "DynamixelGateway.hh"
#include <iostream>
#include "Timer.hh"

int main(int argc, char * argv[]){
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
  if (dgateway.SetAutoReadWrite())
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

  for (int jj=0; jj<50; jj++)
  {
    timer0.Tic();
    if (dgateway.GetJointAngles(angles))
    {
      printf("could not get joint angles\n");
      return -1;
    }


    for (int ii=0; ii<nServos; ii++)
      printf("%d ",(uint16_t)angles[ii]);
    printf("\n");

    angle = (uint16_t)angle+1;

    if (angle < 400)
      angle = 400;

    if (angle > 600)
      angle = 400;

    for (int ii=0; ii<nServos; ii++)
      desAngles[ii] = angle;

    if (dgateway.SetJointAngles(desAngles))
    {
      printf("could not set joint angles\n");
      return -1;
    }

    usleep(10000);

    if (dgateway.SetManual())
    {
      printf("could not set manual mode\n");
      return -1;
    }

    usleep(5000);

    if (dgateway.SetAutoReadWrite())
    {
      printf("could not set auto mode\n");
      return -1;
    }

    //timer0.Toc(true);
  }

  dgateway.Disconnect();

  return 0;
}

