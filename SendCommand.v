`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:44:40 07/14/2015 
// Design Name: 
// Module Name:    SendCommand 
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
module SendCommand
( input Clk,
  output reg [7:0] SendData,
  output reg SendReq,
  input SendAck,
  input [5:0] Command,
  input [31:0] Args,
  input [6:0] CRC,
  input CmdSend,
  output reg CmdAck
);

  integer Status;
  integer Count;
  reg [7:0] Buffer [5:0];
  
  initial
    begin
	   Status = 0;
		SendData = 8'hFF;
		SendReq = 0;
		CmdAck = 0;
	 end

  always @(posedge Clk)
    begin
	   case(Status)
		  0: begin
		       if (CmdSend == 1) Status = 1;
				 else Status = 0;
		     end
		  1: begin
		       Buffer[0] = {1'b0, 1'b1, Command};
				 Buffer[1] = Args[31:24];
				 Buffer[2] = Args[23:16];
				 Buffer[3] = Args[15:8];
				 Buffer[4] = Args[7:0];
				 Buffer[5] = {CRC, 1'b1};
				 CmdAck = 1;
				 Count = 0;
				 Status = 2;
		     end
		  2: begin
				 if (SendAck == 0)
				   begin
					  SendData = Buffer[Count];
					  SendReq = 1;
					  Status = 3;
					end
				 else Status = 2;
		     end
		  3: begin
		       if (SendAck == 1)
				   begin
					  SendReq = 0;
					  Status = 4;
					end
				 else Status = 3;
		     end
		  4: begin
		       if (Count < 5)
				   begin
					  Count = Count + 1;
					  Status = 2;
					end
				 else Status = 5;
           end
		  5: begin
		       if (SendAck == 0)
				   begin
					  CmdAck = 0;
					  Status = 0;
					end
				 else Status = 5;
		     end
		endcase
	 end

endmodule
