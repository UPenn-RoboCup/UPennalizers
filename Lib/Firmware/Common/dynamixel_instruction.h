#ifndef dynamixel_instruction_h_DEFINED
#define dynamixel_instruction_h_DEFINED

#include <string>
#include <stdint.h>

//Instructions
#define INSTRUCTION_PING           0x01
#define INSTRUCTION_READ_DATA      0x02
#define INSTRUCTION_WRITE_DATA     0x03
#define INSTRUCTION_REG_WRITE      0x04
#define INSTRUCTION_ACTION         0x05
#define INSTRUCTION_RESET          0x06
#define INSTRUCTION_SYNC_WRITE     0x83

//Broadcast ID
#define BROADCAST           0xFE    //b254

#define STARTPACKET         0xFF

//Dynamixel Control Table
#define ADDR_MODEL_NUMBER_L								0x00
#define ADDR_MODEL_NUMBER_H								0x01
#define ADDR_VERSION											0x02
#define ADDR_ID														0x03
#define ADDR_BAUD_RATE										0x04
#define ADDR_RETURN_DELAY									0x05
#define ADDR_CW_ANGLE_LIMIT_L							0x06
#define ADDR_CW_ANGLE_LIMIT_H							0x07
#define ADDR_CCW_ANGLE_LIMIT_L						0x08
#define ADDR_CCW_ANGLE_LIMIT_H						0x09
#define ADDR_HIGHEST_LIMIT_TEMP						0x0B
#define ADDR_LOWEST_LIMIT_VOLTAGE					0x0C
#define ADDR_HIGHEST_LIMIT_VOLTAGE				0x0D
#define ADDR_MAX_TORQUE_L									0x0E
#define ADDR_MAX_TORQUE_H									0x0F
#define ADDR_STATUS_RETURN_LEVEL					0x10
#define ADDR_ALARM_LED										0x11
#define ADDR_ALARM_SHUTDOWN								0x12
#define ADDR_TORQUE_ENABLE								0x18
#define ADDR_LED													0x19
#define ADDR_CW_COMPLIANCE_MARGIN					0x1A
#define ADDR_CCW_COMPLIANCE_MARGIN				0x1B
#define ADDR_CW_COMPLIANCE_SLOPE					0x1C
#define ADDR_CCW_COMPLIANCE_SLOPE					0x1D
#define ADDR_GOAL_POSITION_L							0x1E
#define ADDR_GOAL_POSITION_H							0x1F
#define ADDR_MOVING_SPEED_L								0x20
#define ADDR_MOVING_SPEED_H								0x21
#define ADDR_TORQUE_LIMIT_L								0x22
#define ADDR_TORQUE_LIMIT_H								0x23
#define ADDR_PRESENT_POSITION_L						0x24
#define ADDR_PRESENT_POSITION_H						0x25
#define ADDR_PRESENT_SPEED_L							0x26
#define ADDR_PRESENT_SPEED_H							0x27
#define ADDR_PRESENT_LOAD_L								0x28
#define ADDR_PRESENT_LOAD_H								0x29
#define ADDR_PRESENT_VOLTAGE							0x2A
#define ADDR_PRESENT_TEMPERATURE					0x2B
#define ADDR_REGISTERED_INSTRUCTION				0x2C
#define ADDR_MOVING												0x2E
#define ADDR_LOCK													0x2F
#define ADDR_PUNCH_L											0x30
#define ADDR_PUNCH_H											0x31

#ifdef __cplusplus
extern "C" {
#endif
    
    std::string Instruction_frame(uint8_t ID, uint8_t Inst, uint8_t addr, double data[], uint8_t ndata);
    
    std::string SyncInstruction_frame(uint8_t addr, double IDs[], uint8_t nIDs, double data[], uint8_t ldata);
    
    std::string SyncInstruction_frame2(uint8_t addr, double IDs[], uint8_t nIDs, double data[], uint8_t ldata);
    
    int Instruction(uint8_t ID, uint8_t Inst, uint8_t addr, double data[], uint8_t ndata, uint8_t* instPktPtr);
    
    int SyncInstruction(uint8_t addr, double IDs[], uint8_t nIDs, double data[], uint8_t ldata, uint8_t* instPktPtr);
    
    int WriteData(uint8_t ID, uint8_t addr, double Parameters[], uint8_t nPara, uint8_t* writebuf);
    
    //int SyncWrite(uint8_t addr, double IDs[], uint8_t nIDs, double data[], uint8_t ldata, uint8_t* writebuf);
    
    int ReadData(uint8_t ID, uint8_t addr, double nbytes[], uint8_t* readbuf);
    
    std::string WriteDataFrame(uint8_t ID, uint8_t addr, double Parameters[], uint8_t nPara);
    
    //std::string SyncWriteFrame(uint8_t addr, double IDs[], uint8_t nIDs, double data[], uint8_t ldata);
    
    //std::string ReadDataFrame(uint8_t ID, uint8_t addr, double nbytes[]);
    
    std::string ReadDataFrame(uint8_t ID, uint8_t addr, uint8_t nbytes);
    
    
#ifdef __cplusplus
}
#endif

#endif 
