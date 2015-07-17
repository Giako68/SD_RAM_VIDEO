`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:17:42 07/10/2015 
// Design Name: 
// Module Name:    Test 
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
module Test
( input PixelClk2,
  input VSync,
  output reg [5:0] XOffsetData,
  output reg [9:0] YOffsetData,
  output reg OffsetWrite
);

  integer StatusL1;
  integer Xdir;
  integer Ydir;
  
  initial
    begin
		StatusL1 = 0;
		XOffsetData = 0;
		YOffsetData = 0;
		OffsetWrite = 0;
		Xdir = 1;
		Ydir = 1;
	 end

  always @(negedge PixelClk2)
    begin
	   case(StatusL1)
		  0: begin
		       XOffsetData = 0;
				 YOffsetData = 0;
				 Xdir = 1;
				 Ydir = 1;
				 StatusL1 = 1;
		     end
        1: begin
		       if (VSync == 1) StatusL1 = 2;
		     end
        2: begin
		       if (VSync == 0) StatusL1 = 3;
		     end
		  3: begin
		       OffsetWrite = 1;
				 StatusL1 = 4;
		     end
		  4: begin
		       OffsetWrite = 0;
				 if (XOffsetData == 6'b111111) Xdir = -1;
				 else if (XOffsetData == 6'b000000) Xdir = 1;
				      else Xdir = Xdir;
				 if (YOffsetData == 10'b1111111111) Ydir = -1;
				 else if (YOffsetData == 10'b0000000000) Ydir = 1;
				      else Ydir = Ydir;
             StatusL1 = 5;
		     end
        5: begin
		       XOffsetData = XOffsetData + Xdir;
				 YOffsetData = YOffsetData + Ydir;
				 StatusL1 = 1;
		     end
		  6: begin
		       StatusL1 = 6;
		     end
      endcase
    end

endmodule
