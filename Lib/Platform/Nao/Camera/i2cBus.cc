#include "i2cBus.h"

#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <stdio.h>

int i2c_open(const char *path, int flag)
{
  int i2c_fd = open(path, flag);
  if (i2c_fd < 0) {
    printf("Couldn't open i2c device.");
    return i2c_fd;
  }

  // Check I2C_TENBIT for 7 bit addresses
  int ret;
  if ((ret = ioctl(i2c_fd, I2C_TENBIT, 0)) < 0) {
    printf("I2C_TENBIT");
    return ret;
  }

  return i2c_fd;
}

int i2c_smbus_read_byte_data(int i2c_fd, uint8 address, uint8 command)
{
  int status;
  static struct i2c_smbus_ioctl_data smbus_data;
  static unsigned char smbus_block[I2C_SMBUS_BLOCK_MAX+1]; 

  // i2c slave address:
  if (ioctl(i2c_fd, I2C_SLAVE, address) < 0) {
    printf("I2C_SLAVE");
  }
  
  smbus_data.read_write = I2C_SMBUS_READ; // 1
  smbus_data.command = command;
  smbus_data.size = 2;
  smbus_data.data = (i2c_smbus_data *) smbus_block;
  status = ioctl(i2c_fd, I2C_SMBUS, &smbus_data);

  return (status < 0) ? status : smbus_block[0];
}


int i2c_smbus_write_block_data(int i2c_fd, uint8 address,
			       uint8 command, uint8 size,
			       uint8 length, uint8 *values)
{
  static struct i2c_smbus_ioctl_data smbus_data;
  static unsigned char smbus_block[I2C_SMBUS_BLOCK_MAX+1];

  // i2c slave address:
  if (ioctl(i2c_fd, I2C_SLAVE, address) < 0) {
    printf("I2C_SLAVE\n");
  }

  smbus_data.read_write = I2C_SMBUS_WRITE; // 0
  smbus_data.command = command;
  smbus_data.size = size;
  smbus_data.data = (i2c_smbus_data *) smbus_block;

  if (length > I2C_SMBUS_BLOCK_MAX)
    length = I2C_SMBUS_BLOCK_MAX;
  smbus_block[0] = length;
  for (int i = 0; i < length; i++)
    smbus_block[i+1] = values[i];

  return ioctl(i2c_fd, I2C_SMBUS, &smbus_data);
}
