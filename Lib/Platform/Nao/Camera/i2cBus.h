#ifndef i2cBus_h_DEFINED
#define i2cBus_h_DEFINED

typedef unsigned char uint8;

#ifdef __cplusplus
extern "C" {
#endif

  int i2c_open(const char *path, int flag);
  int i2c_smbus_read_byte_data(int i2c_fd, uint8 address, uint8 command);
  int i2c_smbus_write_block_data(int i2c_fd, uint8 address,
				 uint8 command, uint8 size,
				 uint8 length, uint8 *values);

#ifdef __cplusplus
}
#endif

#endif
