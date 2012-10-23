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

#include "SerialDevice.hh"
#include <stdlib.h>
#include <stdio.h>

//constructor
SerialDevice::SerialDevice()
{
  _fd=-1;
  _connected=false;
  _block=-1;
  _baud=B2400;
  
  _ioMode=IO_BLOCK_W_TIMEOUT;
  _delay_us=0;
  _numTermChars=0;
  _retTermSequence=false;
}

//destructor
SerialDevice::~SerialDevice()
{
  Disconnect();
}

//wrapper for ConnectSerial function
int SerialDevice::Connect(const char * device, const int speed)
{
  return ConnectSerial(device,speed);
}

int SerialDevice::Connect(const char * device, const char * speedStr)
{
  int speed = strtol(speedStr,NULL,10);
  return ConnectSerial(device,speed);
}

//connect to the serial device
int SerialDevice::ConnectSerial(const char * device, const int speed)
{

  if (_connected)
  {
    std::cout << "SerialDevice::ConnectSerial: Warning: already connected" << std::endl;
    return 0;
  }

  //store the device name
  strncpy(_device,device,MAX_DEVICE_NAME_LENGTH);

  // Open the device
  if((_fd = open(_device, O_RDWR | O_NOCTTY | O_NONBLOCK)) < 0)
  //if((_fd = open(_device, O_RDWR | O_NOCTTY)) < 0)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ConnectSerial: Error: Unable to open serial port" << std::endl;
#endif
    return -1;
  }

  //update the connected flag
  _connected=true;

   //set the default IO mode
  if (Set_IO_BLOCK_W_TIMEOUT())
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ConnectSerial: Error: Unable to set the io mode" << std::endl;
#endif
    close(_fd);
    _connected=false;
    return -1;
  }
  
  //set the device type
  _device_type = DEVICE_TYPE_SERIAL;

  if (speed==0)
    return 0;
  
  //save current attributes so they can be restored after use
  if( tcgetattr( _fd, &_oldterm ) < 0 )
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout<<"SerialDevice::ConnectSerial: Error: Unable to get old serial port attributes" << std::endl;
#endif
    close(_fd);
    _connected=false;
    return -1;
  }
  
  //set up the terminal and set the baud rate
  if (SetBaudRate(speed))
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ConnectSerial: Error: Unable to set baud rate" << std::endl;
#endif
    close(_fd);
    _connected=false;
    return -1;
  }

  return 0;
}

int SerialDevice::ConnectTCP(const char * device, const int port, const int buff_size)
{
  //int buffSize, nonblock=1;
	struct sockaddr_in serv_addr;
	struct hostent *hostptr;
	
  
  //check the port
  if ( (port < 0) || (port > 65536) )
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ConnectTCP: Error: bad port number" << std::endl;
#endif
    return -1;
  }
  
  //get the hostname
	if ((hostptr = gethostbyname(device)) == NULL)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ConnectTCP: Error: could not get hostname" << std::endl;
#endif
		return -1;
	}
  
	//Get host info
	bzero((char *) &serv_addr, sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	bcopy(hostptr->h_addr, (char *) &serv_addr.sin_addr, hostptr->h_length);
	serv_addr.sin_port = htons(port);
	
	if ((_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ConnectTCP: Error: could not open a socket" << std::endl;
#endif
		 return -1;
	}
	
	// Set read buffer size
	if (setsockopt(_fd, SOL_SOCKET, SO_RCVBUF, &buff_size, sizeof(int)) < 0)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ConnectTCP: Error: could not set receive buffer size" << std::endl;
#endif
		 close(_fd);
		 return -1;
	}

  //update the connected flag
  _connected=true;
	
	// Set nonblocking I/O so that we can attempt to connect
  if (Set_IO_NONBLOCK_WO_TIMEOUT())
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ConnectTCP: Error: could not set non-blocking io mode" << std::endl;
#endif
    close(_fd);
    _connected=false;
    return -1;
  }
	
	struct timeval selTimeout = {0,DEFAULT_TCP_CONNECT_TIMEOUT_US};
	
	fd_set wrfds;
	FD_ZERO(&wrfds);
	FD_SET(_fd, &wrfds);
	
	connect(_fd, (struct sockaddr *) &serv_addr, sizeof(serv_addr));
	int selret = 0;
	
	selret = select(_fd+1,NULL,&wrfds,NULL,&selTimeout);


  //make sure that we actually connected by getting the status from getsocketopt
  int option_value;
  int option_length=4;  //need to set this value to 4 to let getsockopt know that we are expecting an int (4 bytes)

  if (getsockopt(_fd,SOL_SOCKET,SO_ERROR,(char*)&option_value,(socklen_t*)&option_length) != 0)

  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ConnectTCP: Error: could not get socket option" << std::endl;
#endif
    close(_fd);
    _connected=false;
    return -1;
  }

  //std::cout <<"option length= "<<option_length<<" option value= " << *(int*)option_value<<std::endl;

  if (option_value != 0)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ConnectTCP: Error: could not connect to the server:"<< std::endl;
    std::cout<<strerror(option_value)<<std::endl;
#endif
    close(_fd);
    _connected=false;
    return -1;
  }

  if (selret <= 0)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ConnectTCP: Error: could not connect to the server" << std::endl;
#endif
    close(_fd);
    _connected=false;
    return -1;
  }

  
  //set the default IO mode
  if (Set_IO_BLOCK_W_TIMEOUT())
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ConnectSerial: Error: Unable to set the io mode" << std::endl;
#endif
    close(_fd);
    _connected=false;
    return -1;
  }

  
  _device_type = DEVICE_TYPE_TCP;
  return 0;
}

//disconnect from the device
int SerialDevice::Disconnect()
{
  //check whether we are connected to the device  
  if (!_connected)
  {
    return 0;
  }  

  if (_device_type == DEVICE_TYPE_SERIAL)
  {
    // Restore old terminal settings
    if(tcsetattr(_fd,TCSANOW,&_oldterm) < 0) 
    {
#ifdef SERIAL_DEVICE_DEBUG
      std::cout << "SerialDevice::Disconnect: Failed to restore attributes!" << std::endl;
#endif
    }
  }
  
  // Actually close the device
  if(close(_fd) != 0)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::Disconnect: Failed to close device!" << std::endl;
#endif
    _connected=false;
    return -1;
  }
  
  _connected=false;
  return 0;
}

bool SerialDevice::IsConnected()
{
  return _connected;
}


//convert speed (integer) to baud rate (speed_t)
int SerialDevice::_SpeedToBaud(int speed, speed_t & baud)
{
  switch (speed) 
  {
    case 2400:
      baud=B2400;
      return 0;
    case 4800:
      baud=B4800;
      return 0;
    case 9600:
      baud=B9600;
      return 0;
    case 19200:
      baud=B19200;
      return 0;
    case 38400:
      baud=B38400;
      return 0;
    case 57600:
      baud=B57600;
      return 0;
    case 115200:
      baud=B115200;
      return 0;
    case 230400:
      baud=B230400;
      return 0;
    case 460800:
#ifndef __APPLE__
      baud=B460800;
      return 0;
#endif
    case 921600:
#ifndef __APPLE__
      baud=B921600;
      return 0;
#endif
    case 1000000:
#ifndef __APPLE__
      baud=B1000000;
      return 0;
#endif
    case 2000000:
#ifndef __APPLE__
      baud=B2000000;
      return 0;
#endif

    default:
#ifdef SERIAL_DEVICE_DEBUG
      std::cout << "SerialDevice::speedToBaud: ERROR: unknown baud rate" <<std::endl;
#endif
      return -1;
  }
}

//set the terminal baud rate. Argument can be either an integer (ex. 115200) or speed_t (ex. B115200)
int SerialDevice::SetBaudRate(const int speed)
{
  speed_t tempBaud;

  //check whether we are connected to the device
  if (!_connected)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::FlushInputBuffer: Error: not connected to the device" << std::endl;
#endif
    return -1;
  }

  //convert the integer speed value to speed_t if needed
  if (_SpeedToBaud(speed,tempBaud))
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout<<"SerialDevice::SetBaudRate: Error: bad baud rate" << std::endl;
#endif
    return -1;
  }
  
  //get current port settings
  if( tcgetattr( _fd, &_newterm ) < 0 )
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout<<"SerialDevice::SetBaudRate: Error: Unable to get serial port attributes" << std::endl;
#endif
    return -1;
  }

  //cfmakeraw initializes the port to standard configuration. Use this!
  cfmakeraw( &_newterm );
  
  //set input baud rate
  if (cfsetispeed( &_newterm, tempBaud ) < 0 )
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout<<"SerialDevice::SetBaudRate: Error: Unable to set baud rate" <<std::endl;
#endif
    return -1;
  }
  
  //set output baud rate
  if (cfsetospeed( &_newterm, tempBaud ) < 0 )
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout<<"SerialDevice::SetBaudRate: Error: Unable to set baud rate" <<std::endl;
#endif
    return -1;
  }
  
  //set new attributes 
  if( tcsetattr( _fd, TCSAFLUSH, &_newterm ) < 0 )
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout<<"SerialDevice::SetBaudRate: Error: Unable to set serial port attributes" <<std::endl;
#endif
    return -1;
  }
  
  //make sure queue is empty
  tcflush(_fd, TCIOFLUSH);

  //save the baud rate value
  _baud=tempBaud;

  return 0;
}


int SerialDevice::Set_IO_BLOCK_W_TIMEOUT()
{
  //check whether we are connected to the device  
  if (!_connected)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::Set_IO_BLOCK_WO_TIMEOUT: Error: not connected to the device" << std::endl;
#endif
    return -1;
  }
  
  if (_SetBlockingIO())
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::Set_IO_BLOCK_WO_TIMEOUT: Error: could not set blocking io" << std::endl;
#endif
    return -1;
  }
  _ioMode=IO_BLOCK_W_TIMEOUT;
  _delay_us=0;
  _numTermChars=0;
  _retTermSequence=false;
  
  return 0;
}

int SerialDevice::Set_IO_BLOCK_WO_TIMEOUT()
{
  //check whether we are connected to the device  
  if (!_connected)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::Set_IO_BLOCK_WO_TIMEOUT: Error: not connected to the device" << std::endl;
#endif
    return -1;
  }
  
  if (_SetBlockingIO())
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::Set_IO_BLOCK_WO_TIMEOUT: Error: could not set blocking io" << std::endl;
#endif
    return -1;
  }
  _ioMode=IO_BLOCK_WO_TIMEOUT;
  _delay_us=0;
  _numTermChars=0;
  _retTermSequence=false;
  
  return 0;
}

int SerialDevice::Set_IO_BLOCK_W_TIMEOUT_W_TERM_SEQUENCE(const char * termSequence, int numTermChars, bool retTermSequence)
{
  //check whether we are connected to the device  
  if (!_connected)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::Set_IO_BLOCK_W_TIMEOUT_W_TERM_SEQUENCE: Error: not connected to the device" << std::endl;
#endif
    return -1;
  }
  
  if (_SetBlockingIO())
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::Set_IO_BLOCK_W_TIMEOUT_W_TERM_SEQUENCE: Error: could not set blocking io" << std::endl;
#endif
    return -1;
  }
  
  if (numTermChars < 1 || numTermChars > MAX_NUM_TERM_CHARS)
  {
    std::cout<<" IOMode::Set_IO_BLOCK_W_TIMEOUT_W_TERM_SEQUENCE: ERROR: bad number of chars: " <<numTermChars<<std::endl;
    return -1;
  }
  _ioMode=IO_BLOCK_W_TIMEOUT_W_TERM_SEQUENCE;
  _numTermChars=numTermChars;
  _retTermSequence=retTermSequence;
  memcpy(_termSequence,termSequence, numTermChars*sizeof(char));
  _delay_us=0;
  
  return 0;
}

int SerialDevice::Set_IO_NONBLOCK_WO_TIMEOUT()
{
  //check whether we are connected to the device  
  if (!_connected)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::Set_IO_NONBLOCK_WO_TIMEOUT: Error: not connected to the device" << std::endl;
#endif
    return -1;
  }
  
  if (_SetNonBlockingIO())
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::Set_IO_NONBLOCK_WO_TIMEOUT: Error: could not set non-blocking io" << std::endl;
#endif
    return -1;
  }

  _ioMode=IO_NONBLOCK_WO_TIMEOUT;
  _delay_us=0;
  _numTermChars=0;
  _retTermSequence=false;
  
  return 0;
}

int SerialDevice::Set_IO_NONBLOCK_POLL_W_DELAY_W_TIMEOUT(int delay_us)
{
  //check whether we are connected to the device  
  if (!_connected)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::Set_IO_NONBLOCK_POLL_W_DELAY_W_TIMEOUT: Error: not connected to the device" << std::endl;
#endif
    return -1;
  }
  
  if (_SetNonBlockingIO())
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::Set_IO_NONBLOCK_POLL_W_DELAY_W_TIMEOUT: Error: could not set non-blocking io" << std::endl;
#endif
    return -1;
  }

  _ioMode=IO_NONBLOCK_POLL_W_DELAY_W_TIMEOUT; 
  _delay_us=delay_us;
  _numTermChars=0;
  _retTermSequence=false;
  
  return 0;
}


//set blocking terminal mode
int SerialDevice::_SetBlockingIO()
{  
  //check whether we are connected to the device  
  if (!_connected)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::SetBlockingIO: Error: not connected to the device" << std::endl;
#endif
    return -1;
  }  

  //only set blocking if not already set  
  if (_block != 1)
  {
    // Read the flags
    int flags;
    if((flags = fcntl(_fd,F_GETFL)) < 0) 
    {
#ifdef SERIAL_DEVICE_DEBUG
      std::cout << "SerialDevice::_setBlockingIO: unable to get device flags" << std::endl;
#endif
      return -1;
    } 
  
    // Set the new flags
    if(fcntl(_fd,F_SETFL,flags & (~O_NONBLOCK)) < 0)
    {
#ifdef SERIAL_DEVICE_DEBUG
      std::cout << "SerialDevice::_setBlockingIO: unable to set device flags" << std::endl;
#endif
      return -1;
    }
  
    _block=1;
  }
  return 0;
}

//set non-blocking terminal mode
int SerialDevice::_SetNonBlockingIO()
{
  //check whether we are connected to the device  
  if (!_connected)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::SetNonBlockingIO: Error: not connected to the device" << std::endl;
#endif
    return -1;
  }  

  //only set non-blocking if not already set
  if (_block != 0)
  {
    // Read the flags
    int flags;
    if((flags = fcntl(_fd,F_GETFL)) < 0)
    {
#ifdef SERIAL_DEVICE_DEBUG
      std::cout << "SerialDevice::_setNonBlockingIO failed! - unable to retrieve device flags" << std::endl;
#endif
      return -1;
    }
  
    // Set the new flags
    if(fcntl(_fd,F_SETFL,flags | O_NONBLOCK) < 0)
    {
#ifdef SERIAL_DEVICE_DEBUG
      std::cout << "SerialDevice::_setNonBlockingIO failed! - unable to set device flags" << std::endl;
#endif
      return -1;
    }
  
    _block=0;
  }
  return 0;
}

//delete all the data in the input buffer
int SerialDevice::FlushInputBuffer()
{
  char c[1000];
  //check whether we are connected to the device
  if (!_connected)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::FlushInputBuffer: Error: not connected to the device" << std::endl;
#endif
    return -1;
  }
  
  //TODO tcflush for some reason does not work.. 
  //tcflush(_fd, TCIFLUSH);
  
  int block=_block;
  _SetNonBlockingIO();
  
  //read off all the chars
  while (read(_fd,c,1000) > 0){}
  
  if (block==1)
  {
    _SetBlockingIO();
  }
  
  return 0;
}

//read characters from device
int SerialDevice::ReadChars(char * data, int byte_count, int timeout_us)
{
  //check whether we are connected to the device
  if (!_connected)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ReadChars: Error: not connected to the device" << std::endl;
#endif
    return -1;
  }

//TODO: tcp behaves strangely when connection is closed. The check below does not work
/*
  struct stat fd_info;
  if (fstat(_fd,&fd_info) != 0 )
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ReadChars: Error: file descriptor is not valid" << std::endl;
#endif   
    return -1;
  }
*/
  fd_set watched_fds;
  struct timeval timeout, start, end;
  int bytes_read_total = 0;
  int bytes_left = byte_count;
  int retval;
  int bytes_read;
  int charsMatched=0;

  switch (_ioMode)
  {

    case IO_BLOCK_W_TIMEOUT:
      //set up for the "select" call
      FD_ZERO(&watched_fds);
      FD_SET(_fd, &watched_fds);
      timeout.tv_sec = timeout_us / 1000000;
      timeout.tv_usec = timeout_us % 1000000;


      while (bytes_left) 
      {
        if ((retval = select(_fd + 1, &watched_fds, NULL, NULL, &timeout)) < 1)   //block until at least 1 char is available or timeout
        {                                                                         //error reading chars
          if (retval < 0)
          {
#ifdef SERIAL_DEVICE_DEBUG
            perror("SerialDevice::ReadChars");
#endif
          }
          else                                                                    //timeout
          {
#ifdef SERIAL_DEVICE_DEBUG
            std::cout << "SerialDevice::ReadChars: Error: timeout. #chars read= "<<bytes_read_total <<", requested= "<< byte_count << std::endl;
#endif
          }
          return bytes_read_total;
        }
        bytes_read        = read(_fd, &(data[bytes_read_total]), bytes_left);
        
        if (bytes_read > 0)
        {
          bytes_read_total += bytes_read;
          bytes_left       -= bytes_read;
        }
      }
      return bytes_read_total;

    

    case IO_NONBLOCK_POLL_W_DELAY_W_TIMEOUT:
      gettimeofday(&start,NULL);
      
      while (bytes_left) 
      {
        bytes_read = read(_fd,&(data[bytes_read_total]),bytes_left);
        if ( bytes_read < 1)
        {
          // If a time out then return false
          gettimeofday(&end,NULL);
          if((end.tv_sec*1000000 + end.tv_usec) - (start.tv_sec*1000000 + start.tv_usec) > timeout_us) 
          {
#ifdef SERIAL_DEVICE_DEBUG
            std::cout << "SerialDevice::ReadChars: Error: timeout. #chars read= "<<bytes_read_total <<", requested= "<< byte_count << std::endl;
#endif
            return bytes_read_total;
          }
          usleep(_delay_us);
          continue;
        }

        bytes_read_total += bytes_read;
        bytes_left       -= bytes_read;
      }
      return bytes_read_total;


    case IO_BLOCK_WO_TIMEOUT:
      while (bytes_left) 
      {
        bytes_read = read(_fd,&(data[bytes_read_total]),bytes_left);
        if (bytes_read < 1)
        {
          return -1;
        }
        
        bytes_read_total += bytes_read;
        bytes_left       -= bytes_read;
      }
      return bytes_read_total;

    case IO_NONBLOCK_WO_TIMEOUT:
      bytes_read = read(_fd,&(data[0]),bytes_left);
      if (bytes_read < 0) bytes_read=0;
      return bytes_read;
      
      
    case IO_BLOCK_W_TIMEOUT_W_TERM_SEQUENCE:
    
      //set up for the "select" call
      FD_ZERO(&watched_fds);
      FD_SET(_fd, &watched_fds);
      timeout.tv_sec = timeout_us / 1000000;
      timeout.tv_usec = timeout_us % 1000000;

      while (bytes_left) {
        if ((retval = select(_fd + 1, &watched_fds, NULL, NULL, &timeout)) < 1)   //block until at least 1 char is available or timeout
        {                                                                         //error reading chars
          if (retval < 0) 
          {
#ifdef SERIAL_DEVICE_DEBUG
            perror("SerialDevice::ReadChars");
#endif
          }
          else                                                                    //timeout
          {
#ifdef SERIAL_DEVICE_DEBUG
            std::cout << "SerialDevice::ReadChars: Error: timeout. The terminating sequence has not been read"<< std::endl;
#endif
          }
          return -1;
        }
        bytes_read = read(_fd, &(data[bytes_read_total]), 1);
        
        if (bytes_read==1)
        {
          if (data[bytes_read_total]==_termSequence[charsMatched])
          {
            charsMatched++;
          }
          else 
          {
            charsMatched=0;
          }
          
          //std::cout<<data[bytes_read_total];
          bytes_read_total += bytes_read;
          bytes_left       -= bytes_read;
          
          if (charsMatched==_numTermChars)
          {
            if (_retTermSequence)
            {
              return bytes_read_total;
            }
            
            else 
            {
              return bytes_read_total-_numTermChars;
            }
          }
        }
      }
#ifdef SERIAL_DEVICE_DEBUG
      std::cout << "SerialDevice::ReadChars: Error: Read too much data. The terminating sequence has not been read"<< std::endl;
#endif
      return -1;

    default:
#ifdef SERIAL_DEVICE_DEBUG
      std::cout << "SerialDevice::ReadChars: Error: Bad io mode " << std::endl;
#endif
      return -1;

  }
}

int SerialDevice::WriteChars(const char * data, int byte_count, int delay_us)
{
  int bytes_written_total=0;
  int bytes_written;
  int bytes_left=byte_count;
    
  
  //check whether we are connected to the device  
  if (!_connected)
  {
#ifdef SERIAL_DEVICE_DEBUG
    std::cout << "SerialDevice::ReadChars: Error: not connected to the device" << std::endl;
#endif
    return -1;
  }
  
  if (delay_us==0)
  {
    bytes_written_total=write(_fd,data,byte_count);
  }
  
  else
  {
    while (bytes_left)
    {
      bytes_written=write(_fd,&(data[bytes_written_total]),1);
      if (bytes_written < 0)
      {
#ifdef SERIAL_DEVICE_DEBUG
        perror("SerialDevice::ReadChars");
#endif
      }
      if (bytes_written < 1)
      {
#ifdef SERIAL_DEVICE_DEBUG
        std::cout << "SerialDevice::WriteChars: Error: Could not write a char. #chars written= "<<bytes_written_total <<", requested= "<< byte_count << std::endl;
#endif
        return bytes_written_total;
      }

      bytes_written_total += bytes_written;
      bytes_left       -= bytes_written;
      usleep(delay_us);
    }
  }  
  
  tcdrain(_fd);   //wait till all the data written to the file descriptor is transmitted

  return bytes_written_total;
}


double SerialDevice::GetLastInputPacketTime()
{
  return 0;
}
