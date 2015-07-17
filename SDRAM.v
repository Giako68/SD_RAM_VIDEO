`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Module Name:    SDRAM_Controller 
//
//////////////////////////////////////////////////////////////////////////////////
module SDRAM
( input PixelClk2,
  output SDRAMCK,
  output reg [4:0] CMD,
  output reg [1:0] DQM,
  output reg [1:0] BANK,
  output reg [12:0] ADDR,
  inout [15:0] DATA,
  input [23:0] ExtAddr,
  input [15:0] ExtDataWrite,
  input [1:0] ExtDataMask,
  output reg [15:0] ExtDataRead,
  input ExtOP,
  input ExtReq,
  output reg ExtReady,
  input [10:0] GetRow,
  input StartBuffer,
  output reg [8:0] BufferAddr,
  output reg [15:0] BufferData,
  output reg BufferWrite
);

//synthesis attribute IOB of CMD is "TRUE"
//synthesis attribute IOB of DQM is "TRUE"
//synthesis attribute IOB of BANK is "TRUE"
//synthesis attribute IOB of ADDR is "TRUE"

  reg  [15:0] SdramDataIn;
  wire [15:0] SdramDataOut;
  reg  TriState;

  IOBUF IO_0(.I(SdramDataIn[0]),   .O(SdramDataOut[0]),  .T(TriState), .IO(DATA[0]));
  IOBUF IO_1(.I(SdramDataIn[1]),   .O(SdramDataOut[1]),  .T(TriState), .IO(DATA[1]));
  IOBUF IO_2(.I(SdramDataIn[2]),   .O(SdramDataOut[2]),  .T(TriState), .IO(DATA[2]));
  IOBUF IO_3(.I(SdramDataIn[3]),   .O(SdramDataOut[3]),  .T(TriState), .IO(DATA[3]));
  IOBUF IO_4(.I(SdramDataIn[4]),   .O(SdramDataOut[4]),  .T(TriState), .IO(DATA[4]));
  IOBUF IO_5(.I(SdramDataIn[5]),   .O(SdramDataOut[5]),  .T(TriState), .IO(DATA[5]));
  IOBUF IO_6(.I(SdramDataIn[6]),   .O(SdramDataOut[6]),  .T(TriState), .IO(DATA[6]));
  IOBUF IO_7(.I(SdramDataIn[7]),   .O(SdramDataOut[7]),  .T(TriState), .IO(DATA[7]));
  IOBUF IO_8(.I(SdramDataIn[8]),   .O(SdramDataOut[8]),  .T(TriState), .IO(DATA[8]));
  IOBUF IO_9(.I(SdramDataIn[9]),   .O(SdramDataOut[9]),  .T(TriState), .IO(DATA[9]));
  IOBUF IO_10(.I(SdramDataIn[10]), .O(SdramDataOut[10]), .T(TriState), .IO(DATA[10]));
  IOBUF IO_11(.I(SdramDataIn[11]), .O(SdramDataOut[11]), .T(TriState), .IO(DATA[11]));
  IOBUF IO_12(.I(SdramDataIn[12]), .O(SdramDataOut[12]), .T(TriState), .IO(DATA[12]));
  IOBUF IO_13(.I(SdramDataIn[13]), .O(SdramDataOut[13]), .T(TriState), .IO(DATA[13]));
  IOBUF IO_14(.I(SdramDataIn[14]), .O(SdramDataOut[14]), .T(TriState), .IO(DATA[14]));
  IOBUF IO_15(.I(SdramDataIn[15]), .O(SdramDataOut[15]), .T(TriState), .IO(DATA[15]));

  ODDR2 ExportClock(.D0(1'b1), .D1(1'b0), .C0(PixelClk2), .C1(!PixelClk2), .Q(SDRAMCK), .S(1'b0), .R(1'b0), .CE(1'b1));

  `define CMD_ACTIVATE		5'b10011
  `define CMD_PRECHARGE		5'b10010
  `define CMD_WRITE			5'b10100
  `define CMD_READ			5'b10101
  `define CMD_MODE			5'b10000
  `define CMD_NOP				5'b10111
  `define CMD_REFRESH		5'b10001

  // PixelClk2 = 83.200MHz  ~ 12ns
  // 8192 AutoRefresh in 64ms --> At most a AutoRefresh every 651 clock
  `define REFRESH_TICKS		600

  integer Status;
  integer WaitCounter;
  integer RefreshCountdown;
  integer RefreshCounter;

  reg [23:0] SaveAddr;
  reg [15:0] SaveData;
  reg [1:0]  SaveDQM;
  reg        SaveOP;
  reg [23:0] RowAddr;
  reg [10:0] WordCount;
  reg [15:0] ReadData;

  initial
    begin
	   TriState = 1;
		CMD = `CMD_NOP;
		DQM = 2'b00;
		BANK = 2'b00;
		ADDR = 13'h0000;
		SdramDataIn = 16'h0000;
		ExtDataRead = 16'h0000;
		ExtReady = 0;
		Status = 0;
		WaitCounter = 0;
		RefreshCountdown = 0;
		RefreshCounter = 0;
		BufferWrite = 0;
		BufferAddr = 9'h000;
		BufferData = 16'h0000;
		ReadData = 16'h0203;
	 end
	 
  always @(posedge PixelClk2)
    begin
	   case(Status)
		 15: begin
		       ExtDataRead = SdramDataOut;
		     end
		 53: begin
		       ReadData = SdramDataOut;
		     end
		 54: begin
		       ReadData = SdramDataOut;
		     end
		endcase
	 end
	 
  always @(negedge PixelClk2)
    begin
	   if (RefreshCountdown > 0) RefreshCountdown = RefreshCountdown - 1;
		else begin
				 RefreshCounter = RefreshCounter + 1;
				 RefreshCountdown = `REFRESH_TICKS;
		     end
	   case(Status)
		  0: begin
		       CMD = `CMD_NOP;
				 WaitCounter = 21000;  // 21000 * 12ns ~= 250us
				 Status = 1;
		     end
		  1: begin
		       CMD = `CMD_NOP;
		       if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else Status = 2;
		     end
		  2: begin
		       CMD = `CMD_PRECHARGE;
				 ADDR[10] = 1;
				 WaitCounter = 2;      // 2 * 12ns = 24ns (tRP)
				 Status = 3;
		     end
		  3: begin
		       CMD = `CMD_NOP;
		       if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else Status = 4;
		     end
		  4: begin
		       CMD = `CMD_MODE;
				 BANK = 2'b00;
				 ADDR = 13'b0001000110000;  // CAS=3 No Burst mode
				 WaitCounter = 1;           // 1 * 12ns = 12ns (tMRD)
             Status = 5;				 
		     end
		  5: begin
		       CMD = `CMD_NOP;
		       if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else Status = 6;
		     end
		  6: begin
		       CMD = `CMD_REFRESH;
				 WaitCounter = 5;          // 5 * 12ns = 60ns (tRC)
				 Status = 7;
		     end
		  7: begin
		       CMD = `CMD_NOP;
		       if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else Status = 8;
		     end
		  8: begin
		       CMD = `CMD_REFRESH;
				 WaitCounter = 5;          // 5 * 12ns = 60ns (tRC)
				 Status = 9;
		     end
		  9: begin
		       CMD = `CMD_NOP;
		       if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else begin
				        RefreshCounter = 0;
						  RefreshCountdown = `REFRESH_TICKS;
						  ExtReady = 1;
				        Status = 10;
						end
		     end
	    10: begin
		       if (RefreshCounter > 0)
				   begin
					  RefreshCounter = RefreshCounter - 1;
					  CMD = `CMD_REFRESH;
					  WaitCounter = 5;
					  Status = 11;
					end
				 else if (StartBuffer == 1)
				        begin
					       BufferAddr = 9'h1FF;
					       RowAddr = {4'h0, GetRow, 9'h000};
					       WordCount = 512;
					       Status = 50;
					     end
				      else
				        begin
					       if (ExtReq == 1)
					         begin
						        SaveAddr = ExtAddr;
							     SaveData = ExtDataWrite;
								  SaveDQM = ExtDataMask;
							     SaveOP = ExtOP;
							     ExtReady = 0;
							     CMD = `CMD_ACTIVATE;
							     BANK = ExtAddr[23:22];
							     ADDR = ExtAddr[21:9];
							     WaitCounter = 2;        // 2 * 12ns = 24ns (tRCD)
							     Status = 12;
						      end
					       else Status = 10;
					     end
           end
       11: begin
		       CMD = `CMD_NOP;
		       if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else Status = 10;
           end
       12: begin
		       CMD = `CMD_NOP;
		       if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else Status = (SaveOP == 0) ? 13 : 16;
           end
		 13: begin
		       CMD = `CMD_READ;
				 BANK = SaveAddr[23:22];
				 ADDR = {4'b0010, SaveAddr[8:0]};
				 WaitCounter = 2;
				 Status = 14;
		     end
       14: begin
		       CMD = `CMD_NOP;
		       if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else Status = 15;
           end
       15: begin
		       CMD = `CMD_NOP;
				 WaitCounter = 3;
				 Status = 17;
           end
		 16: begin
		       CMD = `CMD_WRITE;
				 BANK = SaveAddr[23:22];
				 ADDR = {4'b0010, SaveAddr[8:0]};
				 TriState = 0;
				 DQM = SaveDQM;
				 SdramDataIn = SaveData;
				 WaitCounter = 6;
				 Status = 17;
		     end
       17: begin
		       CMD = `CMD_NOP;
				 TriState = 1;
				 DQM = 2'b00;
		       if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else begin
				        ExtReady = 1;
				        Status = 10;
						end
           end
		 50: begin
		       CMD = `CMD_ACTIVATE;
				 BANK = RowAddr[23:22];
				 ADDR = RowAddr[21:9];
				 WaitCounter = 2;        // 2 * 12ns = 24ns (tRCD)
				 Status = 51;
		     end
       51: begin
		       CMD = `CMD_NOP;
		       if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else begin
				        WaitCounter = 3;
				        Status = 52;
						end
           end
		 52: begin
		       CMD = `CMD_READ;
				 BANK = RowAddr[23:22];
				 ADDR = {4'b0000, RowAddr[8:0]};
				 RowAddr = RowAddr + 1;
				 WordCount = WordCount - 1;
				 if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else Status = 53;
		     end
		 53: begin
		       CMD = `CMD_READ;
				 BANK = RowAddr[23:22];
				 ADDR = {4'b0000, RowAddr[8:0]};
				 RowAddr = RowAddr + 1;
				 BufferAddr = BufferAddr + 1;
				 BufferData = ReadData;
				 BufferWrite = 1;
				 if (WordCount > 0) WordCount = WordCount - 1;
				 else begin
				        WaitCounter = 3;
				        Status = 54;
						end
		     end
       54: begin
		       CMD = `CMD_NOP;
				 BufferAddr = BufferAddr + 1;
				 BufferData = ReadData;
				 BufferWrite = 1;
				 if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else Status = 56;
           end
		 56: begin
		       CMD = `CMD_PRECHARGE;
				 ADDR[10] = 1;
				 BufferWrite = 0;
				 WaitCounter = 2;      // 2 * 12ns = 24ns (tRP)
				 Status = 57;
		     end
		 57: begin
		       CMD = `CMD_NOP;
		       if (WaitCounter > 0) WaitCounter = WaitCounter - 1;
				 else Status = 10;
		     end
		endcase
	 end

endmodule
