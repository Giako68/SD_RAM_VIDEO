`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:57:44 07/13/2015 
// Design Name: 
// Module Name:    SPI 
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
module SPI
( input Clk,
  // SPI Host interface
  output reg MOSI,
  input MISO,
  output reg SCLK,
  output reg SCE,
  // Controller interface
  input Enable,
  input Speed,             // 0:LowSpeed  1:HighSpeed
  input [7:0] SendData,
  input SendReq,
  output reg SendAck,
  output reg [7:0] RecvData,
  output reg RecvAdv,
  input RecvAck
);

  // ClkPeriod = Clk period in ns, default 20ns = 50MHz 
  parameter real ClkPeriod = 20.0;
  // Low Speed = 400KHz
  `define LO_SPEED_TICKS_UP	$rtoi(((1.00 / 400000.00) / (ClkPeriod * 1.0E-9)) / 2.00)  
  `define LO_SPEED_TICKS_DW	($rtoi((1.00 / 400000.00) / (ClkPeriod * 1.0E-9)) - `LO_SPEED_TICKS_UP)
  // High Speed = 5MHz
  `define HI_SPEED_TICKS_UP	$rtoi(((1.00 / 5000000.00) / (ClkPeriod * 1.0E-9)) / 2.00)  
  `define HI_SPEED_TICKS_DW	($rtoi((1.00 / 5000000.00) / (ClkPeriod * 1.0E-9)) - `HI_SPEED_TICKS_UP)

  integer ClkCounter;
  integer ClkStatus;
  integer Counter;
  reg [7:0] ShiftReg;

  initial
    begin
	   ClkCounter = 0;
		ClkStatus = 0;
		MOSI = 1;
		SCLK = 0;
		SCE = 1;
		SendAck = 0;
		ShiftReg = 8'hFF;
	 end
	 
  always @(posedge Clk)
    begin
		if (SendReq == 1) SendAck = 1; else begin end
      if (RecvAck == 1) RecvAdv = 0; else begin end 
		if (Enable == 0) SCE = 1; else begin end
	   case(ClkStatus)
		  0: begin
		       ClkCounter = 0;
				 SCLK = 0;
				 ClkStatus = 2;
		     end
		  1: begin
		       if (ClkCounter > 1) ClkCounter = ClkCounter - 1;
			    else begin
				        ClkCounter = (Speed == 0) ? `LO_SPEED_TICKS_DW : `HI_SPEED_TICKS_DW;
						  SCLK = 0;
						  ClkStatus = 2;
						  // SCLK negedge -- SPI Shift
						  if (Enable == 1)
						    begin
						      if (SCE == 1)
						        begin
							       SCE = 0;
								    if (SendAck == 1)
                              begin
									     ShiftReg = {SendData[6:0],1'b0};
										  MOSI = SendData[7];
								        SendAck = 0;
                              end
                            else 
									   begin
									     ShiftReg = 8'b11111111;
										  MOSI = 1;
										end
                            Counter = 7;
							     end
						      else
						        begin
							       if (Counter > 0) 
								      begin
								        Counter = Counter - 1;
									     MOSI = ShiftReg[7];
										  ShiftReg = {ShiftReg[6:0],1'b0};
								      end
								    else
								      begin
								        if (SendAck == 1)
                                  begin
									         ShiftReg = {SendData[6:0],1'b0};
												MOSI = SendData[7];
								            SendAck = 0;
                                  end
                                else
                                  begin										  
										      ShiftReg = 8'b11111111;
												MOSI = 1;
											 end
                                Counter = 7;
								      end
							     end
							 end
                    else MOSI = 1;							 
				      end
		     end
		  2: begin
		       if (ClkCounter > 1) ClkCounter = ClkCounter - 1;
			    else begin
				        ClkCounter = (Speed == 0) ? `LO_SPEED_TICKS_UP : `HI_SPEED_TICKS_UP;
						  SCLK = 1;
						  ClkStatus = 1;
  					     // SCLK posedge -- SPI Latch
						  if (SCE == 0) 
						    begin
							   ShiftReg[0] = MISO;
								if (Counter == 0)
								  begin
								    RecvData = ShiftReg;
									 RecvAdv = 1;
								  end
								else begin
								     end
							 end
						  else begin
						       end
				      end
		     end
		endcase
	 end

endmodule
