`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:37:28 07/09/2015 
// Design Name: 
// Module Name:    DVI_OUT 
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
module DVI_OUT
( input PixelClk,
  input PixelClk2,
  input PixelClk10,
  input SerDesStrobe,
  input [7:0] Red,
  input [7:0] Green,
  input [7:0] Blue,
  input HSync,
  input VSync,
  input VideoEnable,
  output [3:0] TMDS_out_P,
  output [3:0] TMDS_out_N
);

  wire [9:0] EncRed;
  wire [9:0] EncGreen;
  wire [9:0] EncBlue;
  wire SerOutRed;
  wire SerOutGreen;
  wire SerOutBlue;
  wire SerOutClock;

  Component_encoder CE_Red(.Data(Red), .C0(1'b0), .C1(1'b0), .DE(VideoEnable), .PixClk(PixelClk), .OutEncoded(EncRed));
  Component_encoder CE_Green(.Data(Green), .C0(1'b0), .C1(1'b0), .DE(VideoEnable), .PixClk(PixelClk), .OutEncoded(EncGreen));
  Component_encoder CE_Blue(.Data(Blue), .C0(HSync), .C1(VSync), .DE(VideoEnable), .PixClk(PixelClk), .OutEncoded(EncBlue));

  Serializer_10_1 SER_Red(.Data(EncRed), .Clk_10(PixelClk10), .Clk_2(PixelClk2), .Strobe(SerDesStrobe), .Out(SerOutRed));
  Serializer_10_1 SER_Green(.Data(EncGreen), .Clk_10(PixelClk10), .Clk_2(PixelClk2), .Strobe(SerDesStrobe), .Out(SerOutGreen));
  Serializer_10_1 SER_Blue(.Data(EncBlue), .Clk_10(PixelClk10), .Clk_2(PixelClk2), .Strobe(SerDesStrobe), .Out(SerOutBlue));
  Serializer_10_1 SER_Clock(.Data(10'b0000011111), .Clk_10(PixelClk10), .Clk_2(PixelClk2), .Strobe(SerDesStrobe), .Out(SerOutClock));
  
  OBUFDS OutBufDif_B(.I(SerOutBlue),  .O(TMDS_out_P[0]), .OB(TMDS_out_N[0]));
  OBUFDS OutBufDif_G(.I(SerOutGreen), .O(TMDS_out_P[1]), .OB(TMDS_out_N[1]));
  OBUFDS OutBufDif_R(.I(SerOutRed),   .O(TMDS_out_P[2]), .OB(TMDS_out_N[2]));
  OBUFDS OutBufDif_C(.I(SerOutClock), .O(TMDS_out_P[3]), .OB(TMDS_out_N[3]));

endmodule
