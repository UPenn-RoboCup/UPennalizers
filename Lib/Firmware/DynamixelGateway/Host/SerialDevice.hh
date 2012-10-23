/* Driver for reading data from a serial port

    Aleksandr Kushleyev <akushley(at)seas(dot)upenn(dot)edu>
    University of Pennsylvania, 2008

    BSD license.
    --------------------------------------------------------------------
    Copyright (c) 2008 Aleksandr Kushleyev
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:
    1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    3. The name of the author may not be used to endorse or promote products
      derived from this software without specific prior written permission.

      THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
      IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
      OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
      IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
      INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
      NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
      THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/


#ifndef SERIAL_DEVICE_HH
#define SERIAL_DEVICE_HH

//#define SERIAL_DEVICE_DEBUG

#include <iostream>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <sys/time.h>
#include <errno.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <sys/stat.h>
#include <string.h>


#define MAX_DEVICE_NAME_LENGTH 128
#define DEFAULT_READ_TIMEOUT_US 1000000

//list the io modes here
enum { IO_BLOCK_W_TIMEOUT,
       IO_NONBLOCK_POLL_W_DELAY_W_TIMEOUT,
       IO_BLOCK_WO_TIMEOUT,
       IO_NONBLOCK_WO_TIMEOUT,
       IO_BLOCK_W_TIMEOUT_W_TERM_SEQUENCE,
       IO_BLOCK_WO_TIMEOUT_W_TERM_SEQUENCE
     };

#define DEFAULT_IO_MODE IO_BLOCK_W_TIMEOUT
#define MAX_NUM_TERM_CHARS 128

#define DEVICE_TYPE_SERIAL 0
#define DEVICE_TYPE_TCP 1

#define DEFAULT_TCP_BUFFER_SIZE 4096
#define DEFAULT_TCP_CONNECT_TIMEOUT_US 500000

class SerialDevice{
  public:

  SerialDevice();
  ~SerialDevice();

  int ConnectSerial(const char * device, const int speed=0);
  int Connect(const char * device, const char * speedStr);
  int ConnectTCP(const char * device, const int port, const int buff_size = DEFAULT_TCP_BUFFER_SIZE);
  int Connect(const char * device, const int speed=0);          //connect to the device and set the baud rate
  int Disconnect();                              //disconnect from the device
  int SetBaudRate(const int baud);                     //set the baud rate
  
  bool IsConnected();

  int FlushInputBuffer();                        //flush input buffer

  int ReadChars(char * data, int byte_count, int timeout_us=DEFAULT_READ_TIMEOUT_US);       //read a number of characters
  int WriteChars(const char * data, int byte_count, int delay_us=0);      //write a number of characters

  int Set_IO_BLOCK_W_TIMEOUT();
  int Set_IO_NONBLOCK_POLL_W_DELAY_W_TIMEOUT(int delay);
  int Set_IO_BLOCK_WO_TIMEOUT();
  int Set_IO_NONBLOCK_WO_TIMEOUT();
  int Set_IO_BLOCK_W_TIMEOUT_W_TERM_SEQUENCE(const char * termSequence, int numTermChars, bool retTermSequence=true);
  int Set_IO_BLOCK_WO_TIMEOUT_W_TERM_SEQUENCE(const char * termSequence, int numTermChars, bool retTermSequence=true);
  double GetLastInputPacketTime();

  private:

  char _device[MAX_DEVICE_NAME_LENGTH];   //devince name
  speed_t _baud;                          //baud rate
  int _fd;                                //file descriptor
  bool _connected;                        //status
  int _block;                            //block / non-block IO
  int _port;                             //port number for TCP/IP
  int _device_type;                       //serial or TCP
  
  int _ioMode, _delay_us, _numTermChars;
  char _termSequence[MAX_NUM_TERM_CHARS];
  bool _retTermSequence;

  int _SetBlockingIO();                           //set blocking IO
  int _SetNonBlockingIO();                        //set non-blocking IO
  int _SpeedToBaud(int speed, speed_t & baud);         //convert integer speed to baud rate setting

  

  struct termios _oldterm,_newterm;       //terminal structs

};


#endif //SERIAL_DEVICE_HH
