#include "dynamixel.h"
#include <stdlib.h>

uchar dynamixel_checksum(DynamixelPacket *pkt) {
  uchar checksum = 0;
  uchar *byte = (uchar *) pkt;
  int i;
  for (i = 2; i < pkt->length+3; i++) {
    checksum += byte[i];
  }
  checksum ^= 0xFF; // xor
  return checksum;
}

// Process incoming character using finite state machine
// and return next index in packet (-1 if complete and well-formed)
int dynamixel_input(DynamixelPacket *pkt, uchar c, int n) {
  if (n < 0) n = 0;
  ((uchar *)pkt)[n] = c;

  // Check header
  if ((n <= 1) && (c != DYNAMIXEL_PACKET_HEADER))
    return 0;
  else if (n == pkt->length+3) {
    if (c == dynamixel_checksum(pkt))
      // Complete packet
      return -1;
    else
      // Bad checksum
      return 0;
  }
  else if (n > pkt->length+3)
    return 0;
  
  // Default is to increment index
  return n+1;
}

// Generates instruction packet
DynamixelPacket *dynamixel_instruction(uchar id,
				       uchar inst,
				       uchar *parameter,
				       uchar nparameter) {
  static DynamixelPacket pkt;
  int i;
  pkt.header1 = DYNAMIXEL_PACKET_HEADER;
  pkt.header2 = DYNAMIXEL_PACKET_HEADER;
  pkt.id = id;
  pkt.length = nparameter + 2;
  pkt.instruction = inst;
  for (i = 0; i < nparameter; i++) {
    pkt.parameter[i] = parameter[i];
  }
  pkt.checksum = dynamixel_checksum(&pkt);
  // Place checksum after parameters:
  pkt.parameter[nparameter] = pkt.checksum;
  return &pkt;
}

DynamixelPacket *dynamixel_instruction_read_data(uchar id,
						 uchar address, uchar n) {
  uchar inst = INST_READ;
  uchar nparameter = 2;
  uchar parameter[nparameter];
  parameter[0] = address;
  parameter[1] = n;
  return dynamixel_instruction(id, inst, parameter, nparameter);
}

DynamixelPacket *dynamixel_instruction_write_data(uchar id,
						  uchar address,
						  uchar data[], uchar n) {
  uchar inst = INST_WRITE;
  uchar nparameter = n+1;
  uchar parameter[nparameter];
  int i;
  parameter[0] = address;
  for (i = 0; i < n; i++) {
    parameter[i+1] = data[i];
  }
  return dynamixel_instruction(id, inst, parameter, nparameter);
}

DynamixelPacket *dynamixel_instruction_reg_write(uchar id,
						 uchar address,
						 uchar data[], uchar n) {
  uchar inst = INST_REG_WRITE;
  uchar nparameter = n+1;
  uchar parameter[nparameter];
  int i;
  parameter[0] = address;
  for (i = 0; i < n; i++) {
    parameter[i+1] = data[i];
  }
  return dynamixel_instruction(id, inst, parameter, nparameter);
}

DynamixelPacket *dynamixel_instruction_action() {
  uchar id = DYNAMIXEL_BROADCAST_ID;
  uchar inst = INST_ACTION;
  return dynamixel_instruction(id, inst, NULL, 0);
}

DynamixelPacket *dynamixel_instruction_ping(int id) {
  uchar inst = INST_PING;
  return dynamixel_instruction(id, inst, NULL, 0);
}

DynamixelPacket *dynamixel_instruction_reset(int id) {
  uchar inst = INST_RESET;
  return dynamixel_instruction(id, inst, NULL, 0);
}

DynamixelPacket *dynamixel_instruction_sync_write(uchar address,
						  uchar len,
						  uchar data[], uchar n) {
  uchar id = DYNAMIXEL_BROADCAST_ID;
  uchar inst = INST_SYNC_WRITE;
  uchar nparameter = n+2;
  uchar parameter[nparameter];
  int i;
  parameter[0] = address;
  parameter[1] = len;
  for (i = 0; i < n; i++) {
    parameter[i+2] = data[i];
  }
  return dynamixel_instruction(id, inst, parameter, nparameter);
}

// Generates status packet
DynamixelPacket *dynamixel_status(uchar id,
				  uchar error,
				  uchar *parameter,
				  uchar nparameter) {
  static DynamixelPacket pkt;
  int i;
  pkt.header1 = DYNAMIXEL_PACKET_HEADER;
  pkt.header2 = DYNAMIXEL_PACKET_HEADER;
  pkt.id = id;
  pkt.length = nparameter + 2;
  pkt.instruction = error;
  for (i = 0; i < nparameter; i++) {
    pkt.parameter[i] = parameter[i];
  }
  pkt.checksum = dynamixel_checksum(&pkt);
  // Place checksum after parameters:
  pkt.parameter[nparameter] = pkt.checksum;
  return &pkt;
}
