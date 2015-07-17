`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:12:50 07/09/2015 
// Design Name: 
// Module Name:    CLOCK 
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
module CLOCK
( input CLK32,
  output PixelClk,
  output PixelClk2,
  output PixelClk10,
  output SerDesStrobe
);

  wire pll_fbout;      // PLL Feedback
  wire pll_clk10x;     // From PLL to BUFPLL
  wire pll_clk2x;      // From PLL to BUFG
  wire pll_clk1x;      // From PLL to BUFG
  wire pll_locked;

  PLL_BASE #(.CLKOUT0_DIVIDE(2),   // IO clock 416.000MHz (VCO / 2)
             .CLKOUT1_DIVIDE(10),  // Intermediate clock 83.200MHz (VCO / 10)
             .CLKOUT2_DIVIDE(20),  // Pixel Clock 41.600MHz (VCO / 20)
             .CLKFBOUT_MULT(26),   // VCO = 32.000MHz * 26 = 832.000MHz ...
             .DIVCLK_DIVIDE(1),    // ... 832.000MHz / 1 = 832.000MHz
             .CLKIN_PERIOD(31.25)  // 31.25ns = 32.000MHz
            ) ClockGenPLL(.CLKIN(CLK32),
                          .CLKFBIN(pll_fbout),
                          .RST(1'b0),
                          .CLKOUT0(pll_clk10x),
                          .CLKOUT1(pll_clk2x),
                          .CLKOUT2(pll_clk1x),
                          .CLKOUT3(),
                          .CLKOUT4(),
                          .CLKOUT5(),
                          .CLKFBOUT(pll_fbout),
                          .LOCKED(pll_locked));

  BUFG Clk1x_buf(.I(pll_clk1x), .O(PixelClk));
  BUFG Clk2x_buf(.I(pll_clk2x), .O(PixelClk2));
  
  BUFPLL #(.DIVIDE(5),
           .ENABLE_SYNC("TRUE")
          ) Clk10x_buf(.PLLIN(pll_clk10x),
                       .GCLK(PixelClk2),
                       .LOCKED(pll_locked),
                       .IOCLK(PixelClk10),
                       .SERDESSTROBE(SerDesStrobe),
                       .LOCK());

endmodule
