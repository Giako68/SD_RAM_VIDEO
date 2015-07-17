`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:28:10 07/09/2015 
// Design Name: 
// Module Name:    Graph960x8 
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
module TOP
( input CLK32,
  output [3:0] TMDS_out_P,
  output [3:0] TMDS_out_N,
  output [12:0] SDRAM_ADDR,
  inout  [15:0] SDRAM_DATA,
  output SDRAM_BA0,
  output SDRAM_BA1,
  output SDRAM_UDQM,
  output SDRAM_LDQM,
  output SDRAM_CLK,
  output SDRAM_CKE,
  output SDRAM_CSn,
  output SDRAM_RASn,
  output SDRAM_CASn,
  output SDRAM_WEn,
  output SD_CLK,
  output SD_CD_DAT3,
  input SD_DAT0,
  output SD_DAT1,
  output SD_DAT2,
  output SD_CMD,
  output [7:0] LEDS
);

  wire PixelClk;
  wire PixelClk2;
  wire PixelClk10;
  wire SerDesStrobe;
  wire [7:0] Red;
  wire [7:0] Green;
  wire [7:0] Blue;
  wire HSync;
  wire VSync;
  wire VideoEnable;
  wire [10:0] GetRow;
  wire StartBuffer;
  wire [8:0] BufferAddr;
  wire [15:0] BufferData;
  wire BufferWrite;
  wire [23:0] ExtAddr;
  wire [15:0] ExtDataWrite;
  wire [1:0] ExtDataMask;
  wire [15:0] ExtDataRead;
  wire ExtOP;
  wire ExtReq;
  wire ExtReady;
  wire [7:0] PalAddr;
  wire [31:0] PalData;
  wire PalWrite;
  wire [5:0] XOffsetData;
  wire [9:0] YOffsetData;
  wire OffsetWrite;
  wire [24:0] Address;
  wire [31:0] DataWrite;
  wire [31:0] DataRead;
  wire [1:0] DataSize;
  wire ReadWrite;
  wire Request;
  wire Ready;
  

  CLOCK    CLOCK(CLK32, PixelClk, PixelClk2, PixelClk10, SerDesStrobe);
  
  DVI_OUT  DVI_OUT(PixelClk, PixelClk2, PixelClk10, SerDesStrobe, Red, Green, Blue, HSync, VSync, VideoEnable, TMDS_out_P, TMDS_out_N);
  
  VIDEOGEN VIDEOGEN(PixelClk, PixelClk2, Red, Green, Blue, HSync, VSync, VideoEnable, 
                    GetRow, StartBuffer, BufferAddr, BufferData, BufferWrite,
						  PalAddr, PalData, PalWrite, XOffsetData, YOffsetData, OffsetWrite);
						  
  SDRAM    SDRAM(.PixelClk2(PixelClk2), .SDRAMCK(SDRAM_CLK), .CMD({SDRAM_CKE,SDRAM_CSn,SDRAM_RASn,SDRAM_CASn,SDRAM_WEn}), 
                 .DQM({SDRAM_UDQM,SDRAM_LDQM}), .BANK({SDRAM_BA1,SDRAM_BA0}), .ADDR(SDRAM_ADDR), .DATA(SDRAM_DATA), 
					  .ExtAddr(ExtAddr), .ExtDataWrite(ExtDataWrite), .ExtDataMask(ExtDataMask), .ExtDataRead(ExtDataRead), .ExtOP(ExtOP),
					  .ExtReq(ExtReq), .ExtReady(ExtReady), 
					  .GetRow(GetRow), .StartBuffer(StartBuffer), .BufferAddr(BufferAddr), .BufferData(BufferData), .BufferWrite(BufferWrite));

  MemoryAdapter MA(PixelClk2, ExtAddr, ExtDataWrite, ExtDataMask, ExtDataRead, ExtOP, ExtReq, ExtReady,
                   Address, DataWrite, DataRead, DataSize, ReadWrite, Request, Ready);

  SD SD(PixelClk2, SD_CLK, SD_CD_DAT3, SD_DAT0, SD_DAT1, SD_DAT2, SD_CMD, LEDS,
        Address, DataWrite, DataRead, DataSize, ReadWrite, Request, Ready, PalAddr, PalData, PalWrite);
					  
  Test     Test(PixelClk2, VSync, XOffsetData, YOffsetData, OffsetWrite);					  
  
endmodule
