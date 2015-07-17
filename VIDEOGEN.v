`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:02:35 07/09/2015 
// Design Name: 
// Module Name:    VIDEOGEN 
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
module VIDEOGEN
( input PixelClk,
  input PixelClk2,
  output reg [7:0] Red,
  output reg [7:0] Green,
  output reg [7:0] Blue,
  output reg HSync,
  output reg VSync,
  output reg VideoEnable,
  output reg [10:0] GetRow,
  output reg StartBuffer,
  input [8:0] BufferAddr,
  input [15:0] BufferData,
  input BufferWrite,
  input [7:0] PalAddr,
  input [31:0] PalData,
  input PalWrite,
  input [5:0] XOffsetData,
  input [9:0] YOffsetData,
  input OffsetWrite
);

  `define H_SYNC_START     32
  `define H_SYNC_STOP      129
  `define H_VIDEO_START    258
  `define H_VIDEO_STOP     1217
  `define V_SYNC_START     1
  `define V_SYNC_STOP      4
  `define V_VIDEO_START    20
  `define V_VIDEO_STOP     559

  integer Row;
  integer Col;
  reg [23:0] Pixel;
  wire [31:0] RowBufOut;
  wire [31:0] PaletteOut;
  reg [9:0] ReadBufAddr;
  reg [5:0] XOffset;
  reg [9:0] YOffset;

  initial
    begin
	   Row = 0;
		Col = 0;
		HSync = 0;
		VSync = 0;
		VideoEnable = 0;
		GetRow = 11'h000;
		StartBuffer = 0;
		Pixel = 24'h000000;
		ReadBufAddr = 10'h000;
      Red = 8'h00;
      Green = 8'h00;
      Blue = 8'h00;
		XOffset = 0;
		YOffset = 0;
	 end

  always @(posedge PixelClk2)
    begin
      if (OffsetWrite == 1) 
		  begin
		    XOffset = XOffsetData;
		    YOffset = YOffsetData;
		  end
    end

  always @(negedge PixelClk2)
    begin
	   Pixel = PaletteOut[23:0];
	   ReadBufAddr = ((Col < (`H_VIDEO_START - 2)) ? 10'h000 : (Col - (`H_VIDEO_START - 2))) + XOffset;
    end
	 
  always @(posedge PixelClk)
    begin
      if ((StartBuffer == 1) && (BufferWrite == 1))
         StartBuffer = 0;   		
	   if (Col < `H_VIDEO_STOP) Col = Col + 1;
		else begin
		       Col = 0;
				 if (Row < `V_VIDEO_STOP) 
				    begin
					   Row = Row + 1;
						if (Row >= `V_VIDEO_START)
						   begin
							  GetRow = (Row - `V_VIDEO_START) + YOffset;
							  StartBuffer = 1;
							end
					 end
				 else Row = 0;
		     end
	   HSync = ((Col < `H_SYNC_START) || (Col > `H_SYNC_STOP)) ? 0 : 1;
		VSync = ((Row < `V_SYNC_START) || (Row > `V_SYNC_STOP)) ? 0 : 1;
		if ((Col < `H_VIDEO_START) || (Row < `V_VIDEO_START))
		  begin
		    VideoEnable = 0;
          Red = 8'h00;
          Green = 8'h00;
          Blue = 8'h00;
		  end
		else
		  begin
		    VideoEnable = 1;
          Red = Pixel[23:16];
          Green = Pixel[15:8];
          Blue = Pixel[7:0];
		  end
	 end

  RAMB16BWER #(.DATA_WIDTH_A(18),             // Port A Write Only 16 bit.
               .DATA_WIDTH_B(9),              // Port B Read Only 8 bit.
					.DOA_REG(0), 
					.DOB_REG(0), 
               .EN_RSTRAM_A("FALSE"), 
					.EN_RSTRAM_B("FALSE"), 
					.SIM_DEVICE("SPARTAN6")
				  ) ROWBUFFER (.DOA(), 
				               .DOPA(), 
							      .DOB(RowBufOut), 
							      .DOPB(), 
							      .ADDRA({1'b0,BufferAddr,4'b0000}), 
							      .CLKA(PixelClk2), 
							      .ENA(1'b1),
                           .REGCEA(1'b0), 
							      .RSTA(1'b0), 
							      .WEA({BufferWrite,BufferWrite,BufferWrite,BufferWrite}), 
							      .DIA({16'h0000,BufferData}), 
							      .DIPA(4'h0), 
							      .ADDRB({1'b0,ReadBufAddr,3'b000}), 
							      .CLKB(PixelClk2), 
							      .ENB(1'b1),
                           .REGCEB(1'b0), 
							      .RSTB(1'b0), 
							      .WEB(4'h0), 
							      .DIB(32'h00000000), 
							      .DIPB(4'b0));

  RAMB16BWER #(.DATA_WIDTH_A(36),             // Port A Read Only 32 bit.
               .DATA_WIDTH_B(36),             // Port B Read/Write 32 bit.
					.DOA_REG(0), 
					.DOB_REG(0), 
               .EN_RSTRAM_A("FALSE"), 
					.EN_RSTRAM_B("FALSE"), 
					.SIM_DEVICE("SPARTAN6"),
               .INIT_00(256'h0000FFFF00FFFF0000FF00FF000000FF0000FF0000FF000000FFFFFF00000000)
				  ) PALETTE (.DOA(PaletteOut), 
				             .DOPA(), 
							    .DOB(), 
							    .DOPB(), 
							    .ADDRA({1'b0,RowBufOut[7:0],5'b00000}), 
							    .CLKA(PixelClk2), 
							    .ENA(1'b1),
                         .REGCEA(1'b0), 
							    .RSTA(1'b0), 
							    .WEA(4'h0), 
							    .DIA(32'h00000000), 
							    .DIPA(4'h0), 
							    .ADDRB({1'b0,PalAddr,5'b00000}), 
							    .CLKB(PixelClk2), 
							    .ENB(1'b1),
                         .REGCEB(1'b0), 
							    .RSTB(1'b0), 
							    .WEB({PalWrite,PalWrite,PalWrite,PalWrite}), 
							    .DIB(PalData), 
							    .DIPB(4'b0));

endmodule
