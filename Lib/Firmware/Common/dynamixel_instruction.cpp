/*
 * 
 * 
 * functions to generate dynamixel packets
 *
 * Dinesh Thakur, 02/10.
 * <tdinesh@grasp.upenn.edu>
 */

#include <string.h>
#include "dynamixel_instruction.h"

std::string Instruction_frame(uint8_t ID, uint8_t Inst, uint8_t addr, double data[], uint8_t ndata){

  std::string frame;
  uint8_t checksum = 0;   
 	
	// Total length of the Packet = 7+ndata;
  frame += STARTPACKET;					// 0xFF
  frame += STARTPACKET;					// 0xFF
  frame += ID;						// ID
  frame += ndata+3;				// Length = Number of Data + 3 , or Number of Parameters + 2 
  frame += Inst;					// Instruction
  frame += addr;					// Start Address to write/read data
  checksum += ID + ndata+3 + Inst +addr;
    
  for(int i=0 ; i<ndata; i++) {
    frame += (uint8_t) data[i]; //append the data
    checksum += (uint8_t) data[i]; 
  }  

  frame += ~checksum; 	//append checksum 

  return frame;
}

std::string SyncInstruction_frame(uint8_t addr, double IDs[], uint8_t nIDs, double data[], uint8_t ldata){
    
  std::string frame;
  uint8_t checksum = 0;
  uint8_t lowbyte, highbyte;
  
  int Length = (ldata + 1) * nIDs + 4;
//  int PktLength = Length + 4;

  frame += STARTPACKET;
  frame += STARTPACKET;
  frame += BROADCAST;
  frame += Length;
  frame += INSTRUCTION_SYNC_WRITE;
  frame += addr;
  frame += ldata;
  checksum += BROADCAST + Length + INSTRUCTION_SYNC_WRITE + addr  + ldata;
   
  for(int i = 0 ; i< nIDs; i++){        
    frame += (uint8_t) IDs[i];
    checksum += (uint8_t) IDs[i];
 		lowbyte = (int) data[i] % 256;
    frame += lowbyte;
    checksum += lowbyte;
    highbyte = ( (int)data[i] - lowbyte) / 256; 
    frame += highbyte;
    checksum += highbyte;    	
  }        
    
  frame += ~checksum;      
    
  return frame;
}

std::string SyncInstruction_frame2(uint8_t addr, double IDs[], uint8_t nIDs, double data[], uint8_t ldata){
    
  std::string frame;
  uint8_t checksum = 0;
    
  int Length = (ldata + 1) * nIDs + 4;
//  int PktLength = Length + 4;

  frame += 255;
  frame += 255;
  frame += BROADCAST;
  frame += Length;
  frame += INSTRUCTION_SYNC_WRITE;
  frame += addr;
  frame += ldata;
  checksum += BROADCAST + Length + INSTRUCTION_SYNC_WRITE + addr  + ldata;
    
  for(int i = 0 ; i< nIDs; i++){        
    frame += (uint8_t) IDs[i];
    checksum += (uint8_t) IDs[i];
    frame += (uint8_t) data[i];
    checksum += (uint8_t) data[i];;
  }        
    
 frame += ~checksum;      
    
  return frame;
}

std::string WriteDataFrame(uint8_t ID, uint8_t addr, double Parameters[], uint8_t nPara){
    
  return Instruction_frame(ID, INSTRUCTION_WRITE_DATA, addr, Parameters, nPara);

}
/*
std::string ReadDataFrame(uint8_t ID, uint8_t addr, double nbytes[]){
    
  return Instruction_frame(ID, INSTRUCTION_READ_DATA, addr, nbytes, 1);

}*/

std::string ReadDataFrame(uint8_t ID, uint8_t addr, uint8_t nbytes){
  
  double nb [1] = {nbytes};  
  return Instruction_frame(ID, INSTRUCTION_READ_DATA, addr, nb, 1);

}

/*-----------------Old Implementation ---------------------------*/
int Instruction(uint8_t ID, uint8_t Inst, uint8_t addr, double data[], uint8_t ndata, uint8_t* instPktPtr){
    
  int PktLength = 7+ndata;		// Total length of the Packet
  *(instPktPtr) = 255;			// 0xFF
  *(instPktPtr + 1) = 255;		// 0xFF
  *(instPktPtr + 2) = ID;			// ID
  *(instPktPtr + 3) = ndata+3;	// Length = Number of Data + 3 or Number of Parameters + 2 
  *(instPktPtr + 4) = Inst;		// Instruction
  *(instPktPtr + 5) = addr;		// Start Address to write/read data
    
  for(int i = 6 ; i< 6+ndata; i++)
    *(instPktPtr+i)= (uint8_t) data[i-6];
    
  char checksum;
  int sum = 0;
  for(int i=2;i<=5+ndata;i++)
    sum += *(instPktPtr + i);    
  checksum = 255 - (char)(sum % 256);
  *(instPktPtr+6+ndata) = checksum; 	//append checksum     
    
  return PktLength;
}

int SyncInstruction(uint8_t addr, double IDs[], uint8_t nIDs, double data[], uint8_t ldata, uint8_t* instPktPtr){
    
  int Length = (ldata + 1) * nIDs + 4;
  int PktLength = Length +4;

  *(instPktPtr) = 255;
  *(instPktPtr + 1) = 255;
  *(instPktPtr + 2) = BROADCAST;
  *(instPktPtr + 3) = Length;
  *(instPktPtr + 4) = INSTRUCTION_SYNC_WRITE;
  *(instPktPtr + 5) = addr;
  *(instPktPtr + 6) = ldata;
    
  int col=0;
  for(int i = 7 ; i< 3+Length; i=i+ldata+1){
    *(instPktPtr + i) = (uint8_t) IDs[col];
    //for(int j=0; j<ldata; j++);
    *(instPktPtr + i+1) = (int) data[col] % 256;
    uint8_t lowbyte = *(instPktPtr + i+1);
    *(instPktPtr + i+2) = (data[col] - lowbyte) / 256;
    col++;        	
  }
        
    
  char checksum;
  int sum = 0;
  for(int i=2;i<=2+Length;i++)
    sum += *(instPktPtr + i);    
  checksum = 255 - (char)(sum % 256);
  *(instPktPtr + 3+Length) = checksum;      
    
  return PktLength; 

}

int WriteData(uint8_t ID, uint8_t addr, double Parameters[], uint8_t nPara, uint8_t* writebuf){
    
  return Instruction(ID, INSTRUCTION_WRITE_DATA, addr, Parameters, nPara, writebuf);

}

int ReadData(uint8_t ID, uint8_t addr, double nbytes[], uint8_t* readbuf){
    
  return Instruction(ID, INSTRUCTION_READ_DATA, addr, nbytes, 1, readbuf);

}
