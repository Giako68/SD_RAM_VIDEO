`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:33:37 07/13/2015 
// Design Name: 
// Module Name:    SD 
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
module SD
( input Clk,
  output SD_CLK,
  output SD_CD_DAT3,
  input SD_DAT0,
  output reg SD_DAT1,
  output reg SD_DAT2,
  output SD_CMD,
  output reg [7:0] LEDS,
  output reg [24:0] Address,
  output reg [31:0] DataWrite,
  input [31:0] DataRead,
  output reg [1:0] DataSize,
  output reg ReadWrite,
  output reg Request,
  input Ready,
  output reg [7:0] PalAddr,
  output reg [31:0] PalData,
  output reg PalWrite
);

  reg        Enable;
  reg        Speed;
  wire [7:0] SendData;
  wire       SendReq;
  wire       SendAck;
  wire [7:0] RecvData;
  wire       RecvAdv;
  reg        RecvAck;
  reg  [5:0] Command;
  reg [31:0] Args;
  reg  [6:0] CRC;
  reg        CmdSend;
  wire       CmdAck;
  integer    Status;
  integer    RetStatus;
  integer    S2;
  integer    S3;
  integer    WaitCount;
  integer    Timeout;
  integer    RecvCount;
  reg        LargeResp;
  integer    BlockNum;
  integer    ByteCount;
  reg  [7:0] SaveData;
  reg  [7:0] R1;
  reg [31:0] OCR;
  
  reg        Flag1;
  reg        Flag2;
  reg        Flag3;

  SPI #(.ClkPeriod(12.00)  // PixelClk2 = 83.2MHz ~ 12ns
       ) SPI(.Clk(Clk), .MOSI(SD_CMD), .MISO(SD_DAT0), .SCLK(SD_CLK), .SCE(SD_CD_DAT3), .Enable(Enable), .Speed(Speed), 
             .SendData(SendData), .SendReq(SendReq), .SendAck(SendAck), .RecvData(RecvData), .RecvAdv(RecvAdv), .RecvAck(RecvAck));

  SendCommand SC(.Clk(Clk), .SendData(SendData), .SendReq(SendReq), .SendAck(SendAck), 
                 .Command(Command), .Args(Args), .CRC(CRC), .CmdSend(CmdSend), .CmdAck(CmdAck));

  initial
    begin
	   SD_DAT1 = 0;
		SD_DAT2 = 0;
		LEDS = 8'h00;
	   Enable = 0;
		Speed = 0;
		RecvAck = 0;
		Command = 6'h00;
		Args = 32'h00000000;
		CRC = 7'h00;
		CmdSend = 0;
		Flag1 = 0;
		Flag2 = 0;
		Status = 0;
		Address = 25'h000000;
		DataWrite = 32'h00000000;
		DataSize = 0;
		ReadWrite = 0;
		Request = 0;
		PalAddr = 8'h00;
		PalData = 32'h00000000;
		PalWrite = 0;
		S2 = 0;
		S3 = 0;
	 end

  always @(posedge Clk)
    begin
	   if ((RecvAdv == 1) && (RecvAck == 0)) 
		  begin
          RecvCount = RecvCount + 1;		  
		    RecvAck = 1;
		  end
		else begin end
		if ((RecvAck == 1) && (RecvAdv == 0)) RecvAck = 0;
		else begin end
	   case(Status)
		  0: begin
	          Enable = 0;
		       Speed = 0;
		       RecvAck = 0;
		       Command = 6'h00;
		       Args = 32'h00000000;
		       CRC = 7'h00;
		       CmdSend = 0;
		       WaitCount = 15000;
				 Status = 1;
		     end
		  1: begin
		       //LEDS = Status[7:0];
		       if (WaitCount > 0) WaitCount = WaitCount - 1;
				 else Status = 2;
		     end
		  2: begin
		       //LEDS = Status[7:0];
		       if (CmdAck == 0)
		         begin
					  Enable = 1;
				     Command = 6'h00;
				     Args = 32'h00000000;
				     CRC = 7'h4A;
				     CmdSend = 1;
					  LargeResp = 0;
					  RetStatus = 3;
					  Status = 90;
					end
				 else Status = 2;
		     end
		  3: begin
		       if (R1 == 8'h01) Status = 4;
				 else Status = 88;
		     end
		  4: begin
		       //LEDS = Status[7:0];
		       if (CmdAck == 0)
		         begin
				     Command = 6'h08;
				     Args = 32'h000001AA;
				     CRC = 7'h43;
				     CmdSend = 1;
					  LargeResp = 1;
					  RetStatus = 5;
					  Status = 90;
					end
				 else Status = 4;
		     end
		  5: begin
		       if (R1 == 8'h01) 
				   begin
					  if (OCR[11:0] == 12'h1AA) Status = 6;
					  else Status = 88;
					end
				 else Status = 88;
		     end
		  6: begin
		       //LEDS = Status[7:0];
		       if (CmdAck == 0)
		         begin
				     Command = 6'h37;  // CMD55
				     Args = 32'h00000000;
				     CRC = 7'h00;
				     CmdSend = 1;
					  LargeResp = 0;
					  RetStatus = 7;
					  Status = 90;
					end
				 else Status = 6;
		     end
		  7: begin
		       //LEDS = Status[7:0];
		       if (CmdAck == 0)
		         begin
				     Command = 6'h29;      // ACMD41
				     Args = 32'h40000000;  // HCS = 1
				     CRC = 7'h00;
				     CmdSend = 1;
					  LargeResp = 0;
					  RetStatus = 8;
					  Status = 90;
					end
				 else Status = 7;
		     end
		  8: begin
		       if (R1 == 8'h01) Status = 6;         // R1==0x01  ? Repeat ACMD41
				 else if (R1 == 8'h00) Status = 9;    // R1==0x00  ? Initialization Succedded!
				      else Status = 88;               // R1==other ? Failed!
		     end
        9: begin
		       BlockNum = 0;
				 Speed = 1;
				 Status = 10;
		     end
		 10: begin
		       //LEDS = Status[7:0];
		       if (CmdAck == 0)
		         begin
				     Command = 6'h11;      // CMD17
				     Args = BlockNum;
				     CRC = 7'h00;
				     CmdSend = 1;
					  LargeResp = 0;
					  RetStatus = 11;
					  Status = 90;
					end
				 else Status = 10;
		     end
		 11: begin
		       RecvCount = 0;
				 Status = 12;
		     end
		 12: begin
				 if (RecvCount > 0)
				   begin
					  RecvCount = 0;
					  if (RecvData != 8'hFF)
					    begin
						   if (RecvData == 8'hFE)
							  begin
							    ByteCount = 0;
								 Status = 13;
							  end
							else Status = 88;
						 end
					  else Status = 12;
					end
           end
		 13: begin
				 if (RecvCount > 0)
				   begin
					  RecvCount = 0;
					  SaveData = RecvData;
					  //LEDS = RecvData;
					  Flag1 = !Flag1;
					  if (ByteCount < 511) ByteCount = ByteCount + 1;
					  else Status = 14;
		         end
			    else Status = 13;
		     end
		 14: begin
				 if (RecvCount > 0)
				   begin
					  RecvCount = 0;
					  //LEDS = RecvData;    // CRC1
					  Status = 15;
		         end
			    else Status = 14;
		     end
		 15: begin
				 if (RecvCount > 0)
				   begin
					  RecvCount = 0;
					  //LEDS = RecvData;    // CRC2
					  Status = 16;
		         end
			    else Status = 15;
		     end
		 16: begin
		       if (BlockNum < 3128)      // Palette = 2 blocks -- Image = (540+1023) * 2 blocks
				   begin
					  BlockNum = BlockNum + 1;
					  Status = 10;
					end
				 else Status = 17;
		     end
		 17: begin
		       SaveData = 8'h99;
				 Status = 98;
		     end
			  
			  // ========================================= //

		 88: begin  // Error TIMEOUT -- Slow Blink
		       if (LEDS == SaveData) LEDS = 8'h00;
				 else LEDS = SaveData;
				 WaitCount = 50000000;
				 Status = 89;
		     end
		 89: begin
		       if (WaitCount > 0) WaitCount = WaitCount - 1;
				 else Status = 88;
		     end
			  
			  // ========================================= //

		 90: begin
		       //LEDS = Status[7:0];
		       if (CmdAck == 1) 
				   begin
					  CmdSend = 0;
					  Status = 91;
					end
				 else Status = 90;
		     end
		 91: begin
		       //LEDS = Status[7:0];
		       if (CmdAck == 0) 
				   begin
					  Timeout = 100;
					  RecvCount = 0;
					  Status = 92;
					end
				 else Status = 91;
		     end
		 92: begin
		       //LEDS = Status[7:0];
				 if (RecvCount > 0)
				   begin
					  RecvCount = 0;
				     SaveData = RecvData;
		           if (Timeout > 0)
				       begin
					      Timeout = Timeout - 1;
					      if (SaveData != 8'hFF) Status = 93;
					      else Status = 92;
					    end
				     else Status = 88;
					end
				 else begin end
		     end
		 93: begin
		       //LEDS = Status[7:0];
		       R1 = SaveData;
				 if ((R1 == 8'h01) || (R1 == 8'h00))
				   begin
					  Timeout = 100;
					  if (LargeResp == 1) Status = 94;
					  else Status = RetStatus;
					end
				 else Status = 88;	
		     end
		 94: begin
		       //LEDS = Status[7:0];
				 if (RecvCount > 0)
				   begin
					  RecvCount = 0;
					  OCR[31:24] = RecvData;
					  Timeout = 100;
					  Status = 95;
					end
				 else begin end
			  end		
		 95: begin
		       //LEDS = Status[7:0];
				 if (RecvCount > 0)
				   begin
					  RecvCount = 0;
					  OCR[23:16] = RecvData;
					  Timeout = 100;
					  Status = 96;
					end
				 else begin end
			  end		
		 96: begin
		       //LEDS = Status[7:0];
				 if (RecvCount > 0)
				   begin
					  RecvCount = 0;
					  OCR[15:8] = RecvData;
					  Timeout = 100;
					  Status = 97;
					end
				 else begin end
			  end		
		 97: begin
		       //LEDS = Status[7:0];
				 if (RecvCount > 0)
				   begin
					  RecvCount = 0;
					  OCR[7:0] = RecvData;
					  Timeout = 100;
					  Status = RetStatus;
					end
				 else begin end
			  end		

			  // ========================================= //
			  
		 98: begin  // Succedded -- Fast Blink
		       if (SaveData == 8'h00) SaveData = 8'h80;
		       if (LEDS == SaveData) LEDS = 8'h00;
				 else LEDS = SaveData;
				 WaitCount = 5000000;
				 Status = 99;
		     end
		 99: begin
		       if (WaitCount > 0) WaitCount = WaitCount - 1;
				 else Status = 98;
		     end
		endcase
	 end

  always @(negedge Clk)
    begin
	   case(S2)
		  0: begin
		       PalAddr = 8'h00;
				 S2 = 1;
		     end
		  1: begin
		       if (Flag1 != Flag2)
				   begin
					  Flag2 = Flag1;
					  PalData[31:24] = SaveData;
					  S2 = 2;
					end
				 else S2 = 1;
		     end
		  2: begin
		       if (Flag1 != Flag2)
				   begin
					  Flag2 = Flag1;
					  PalData[23:16] = SaveData;
					  S2 = 3;
					end
				 else S2 = 2;
		     end
		  3: begin
		       if (Flag1 != Flag2)
				   begin
					  Flag2 = Flag1;
					  PalData[15:8] = SaveData;
					  S2 = 4;
					end
				 else S2 = 3;
		     end
		  4: begin
		       if (Flag1 != Flag2)
				   begin
					  Flag2 = Flag1;
					  PalData[7:0] = SaveData;
					  PalWrite = 1;
					  S2 = 5;
					end
				 else S2 = 4;
		     end
		  5: begin
		       PalWrite = 0;
				 if (PalAddr != 8'hFF)
				   begin
					  PalAddr = PalAddr + 1;
					  S2 = 1;
					end
				 else S2 = 6;
		     end
		  6: begin
		       S2 = 6;
		     end
		endcase
	 end

  always @(posedge Clk)
    begin
	   case(S3)
		  0: begin
		       if (S2 == 6)
				   begin
					  Flag3 = Flag1;
  				     Address = 25'h0000000;
					  S3 = 1;
					end
				 else S3 = 0;
		     end
		  1: begin
		       if (Flag1 != Flag3)
				   begin
					  Flag3 = Flag1;
					  DataWrite[7:0] = SaveData;
					  S3 = 2;
					end
				 else S3 = 1;
		     end
		  2: begin
		       if (Flag1 != Flag3)
				   begin
					  Flag3 = Flag1;
					  DataWrite[15:8] = SaveData;
					  S3 = 3;
					end
				 else S3 = 2;
		     end
		  3: begin
		       if (Flag1 != Flag3)
				   begin
					  Flag3 = Flag1;
					  DataWrite[23:16] = SaveData;
					  S3 = 4;
					end
				 else S3 = 3;
		     end
		  4: begin
		       if (Flag1 != Flag3)
				   begin
					  Flag3 = Flag1;
					  DataWrite[31:24] = SaveData;
					  S3 = 6;
					end
				 else S3 = 4;
		     end
		  6: begin
		       if (Ready == 1)
				   begin
					  ReadWrite = 1;
					  DataSize = 2'b11;
					  Request = 1;
					  S3 = 7;
					end
				 else S3 = 6;
		     end
		  7: begin
		       if (Ready == 0)
				   begin
					  Request = 0;
					  S3 =8;
					end
				 else S3 = 7;
		     end
		  8: begin
		       if (Address < 1600512)
				   begin
					  Address = Address + 4;
					  S3 = 1;
					end
				 else S3 = 9;
		     end
		  9: begin
		       S3 = 9;
		     end
		endcase
	 end
	 
endmodule
