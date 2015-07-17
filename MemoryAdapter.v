`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:26:36 07/12/2015 
// Design Name: 
// Module Name:    MemoryAdapter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module MemoryAdapter
( input PixelClk2,
  output reg [23:0] ExtAddr,
  output reg [15:0] ExtDataWrite,
  output reg [1:0] ExtDataMask,
  input [15:0] ExtDataRead,
  output reg ExtOP,
  output reg ExtReq,
  input ExtReady,
  input [24:0] Address,
  input [31:0] DataWrite,
  output reg [31:0] DataRead,
  input [1:0] DataSize,            // 01: 8bit  -  11: 32bit  -  00|10: 16bit
  input ReadWrite,
  input Request,
  output reg Ready  
);

  integer Status;
  reg [24:0] SaveAddr;
  reg [31:0] SaveData;
  reg [1:0] SaveSize;
  reg SaveOP;

  initial
    begin
	   Status = 0;
		ExtReq = 0;
		DataRead = 0;
		ExtAddr = 0;
		ExtDataWrite = 0;
		ExtDataMask = 0;
		ExtOP = 0;
		Ready = 0;
	 end

  always @(posedge PixelClk2)
    begin
	   case(Status)
		  0: begin
		       Ready = 1;
				 Status = 1;
		     end
		  1: begin
		       if (Request == 1)
				   begin
				     SaveAddr = Address;
                 SaveData = DataWrite;
                 SaveSize = (DataSize == 2'b00) ? 2'b10 : DataSize;
                 SaveOP = ReadWrite;
					  Ready = 0;
					  Status = 2;
					end
				 else Status = 1;
		     end
		  2: begin
		       if (ExtReady == 1)
				   begin
					  case(SaveOP)
					    1: begin                      // WRITE
					         case(SaveSize)
					           2'b01: begin           // Byte
								           ExtAddr = SaveAddr[24:1];
											  ExtDataWrite = (SaveAddr[0]==0) ? {8'h00,SaveData[7:0]} : {SaveData[7:0],8'h00};
											  ExtDataMask = (SaveAddr[0]==0) ? 2'b10 : 2'b01;
											  ExtOP = 1;
											  ExtReq = 1;
											  Status = 3;
						               end
						        2'b11: begin           // Double
								           ExtAddr = {SaveAddr[24:2],1'b0};
										     ExtDataWrite = SaveData[15:0];
											  ExtDataMask = 2'b00;
											  ExtOP = 1;
											  ExtReq = 1;
											  Status = 6;
						               end
						        default: begin         // Word
						                   ExtAddr = SaveAddr[24:1];
										       ExtDataWrite = SaveData[15:0];
												 ExtDataMask = 2'b00;
												 ExtOP = 1;
												 ExtReq = 1;
												 Status = 3;
						                 end
					         endcase
							 end
					    default: begin                // READ
					               case(SaveSize)
					                 2'b01: begin     // Byte
										           ExtAddr = SaveAddr[24:1];
													  ExtDataMask = 2'b00;
												     ExtOP = 0;
												     ExtReq = 1;
												     Status = 5;
						                     end
						              2'b11: begin     // Double
										           ExtAddr = {SaveAddr[24:2],1'b0};
													  ExtDataMask = 2'b00;
												     ExtOP = 0;
												     ExtReq = 1;
												     Status = 8;
						                     end
						              default: begin   // Word
						                         ExtAddr = SaveAddr[24:1];
														 ExtDataMask = 2'b00;
												       ExtOP = 0;
												       ExtReq = 1;
												       Status = 4;
						                       end
									   endcase				  
                            end
                 endcase									 
					end
				 else Status = 2;
		     end
		  3: begin
		       if (ExtReady == 0) Status = 0;
				 else Status = 3;
           end		  
		  4: begin
		       if (ExtReady == 0) 
				   begin
                 DataRead = {16'h0000,ExtDataRead};					
					  Status = 0;
					end
				 else Status = 4;
           end		  
		  5: begin
		       if (ExtReady == 0) 
				   begin
					  DataRead = (SaveAddr[0]==1) ? {24'h000000,ExtDataRead[7:0]} : {24'h000000,ExtDataRead[15:8]};					
					  Status = 0;
					end
				 else Status = 5;
           end		  
		  6: begin
		       if (ExtReady == 0) Status = 7;
				 else Status = 6;
           end		  
        7: begin
		       if (ExtReady == 1) 
				   begin
					  ExtAddr = {SaveAddr[24:2],1'b1};
					  ExtDataWrite = SaveData[31:16];
					  ExtDataMask = 2'b00;
					  ExtOP = 1;
					  ExtReq = 1;
					  Status = 3;
					end
				 else Status = 7;
		     end
		  8: begin
		       if (ExtReady == 0) 
				   begin
                 DataRead[15:0] = ExtDataRead;					
					  Status = 9;
					end
				 else Status = 8;
           end		  
        9: begin
		       if (ExtReady == 1) 
				   begin
					  ExtAddr = {SaveAddr[24:2],1'b1};
					  ExtDataMask = 2'b00;
					  ExtOP = 0;
					  ExtReq = 1;
					  Status = 10;
					end
				 else Status = 9;
		     end
		 10: begin
		       if (ExtReady == 0) 
				   begin
                 DataRead[31:16] = ExtDataRead;					
					  Status = 0;
					end
				 else Status = 10;
           end		  
		endcase
	 end

endmodule
