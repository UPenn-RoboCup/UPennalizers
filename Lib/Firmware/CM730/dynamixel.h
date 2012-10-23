#ifndef __DYNAMIXEL_H
#define __DYNAMIXEL_H

#ifdef __cplusplus
extern "C" {
#endif

#define DYNAMIXEL_PACKET_HEADER (255)
#define DYNAMIXEL_PARAMETER_MAX (250)
#define DYNAMIXEL_BROADCAST_ID (254)

#define INST_PING (1)
#define INST_READ (2)
#define INST_WRITE (3)
#define INST_REG_WRITE (4)
#define INST_ACTION (5)
#define INST_RESET (6)
#define INST_SYNC_WRITE (131)

#define ERRBIT_VOLTAGE          (1)
#define ERRBIT_ANGLE            (2)
#define ERRBIT_OVERHEAT         (4)
#define ERRBIT_RANGE            (8)
#define ERRBIT_CHECKSUM         (16)
#define ERRBIT_OVERLOAD         (32)
#define ERRBIT_INSTRUCTION      (64)

typedef unsigned char uchar;

typedef struct DynamixelPacket {
  uchar header1;
  uchar header2;
  uchar id;
  uchar length; // length does not include first 4 bytes
  uchar instruction; // or error for status packets
  uchar parameter[DYNAMIXEL_PARAMETER_MAX]; // reserve for maximum packet size
  uchar checksum; // Needs to be copied at end of parameters
} DynamixelPacket;

  DynamixelPacket *dynamixel_instruction(uchar id,
					 uchar inst,
					 uchar *parameter,
					 uchar nparameter);
  DynamixelPacket *dynamixel_instruction_read_data(uchar id,
						   uchar address, uchar n);
  DynamixelPacket *dynamixel_instruction_write_data(uchar id,
						    uchar address,
						    uchar data[], uchar n);
  DynamixelPacket *dynamixel_instruction_reg_write(uchar id,
						   uchar address,
						   uchar data[], uchar n);
  DynamixelPacket *dynamixel_instruction_action();
  DynamixelPacket *dynamixel_instruction_ping(int id);
  DynamixelPacket *dynamixel_instruction_reset(int id);
  DynamixelPacket *dynamixel_instruction_sync_write(uchar address,
						    uchar len,
						    uchar data[], uchar n);
  

  int dynamixel_input(DynamixelPacket *pkt, uchar c, int n);
  DynamixelPacket *dynamixel_status(uchar id,
				    uchar error,
				    uchar *parameter,
				    uchar nparameter);
  
#ifdef __cplusplus
}
#endif

#endif // __DYNAMIXEL_H
