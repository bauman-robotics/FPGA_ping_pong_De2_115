module main(
  input CLOCK_50 // 50 MHz

 ,input [3:0]KEY

 ,input [2:0]SW

 ,input PS2_CLK
 ,input PS2_DAT

 ,output [8:0] LEDG

 ,output VGA_VS     
 ,output VGA_HS     
 ,output [7:0]VGA_R 
 ,output [7:0]VGA_G 
 ,output [7:0]VGA_B 

 ,output VGA_CLK
 ,output VGA_SYNC_N
 ,output VGA_BLANK_N 
);

wire up_dir, down_dir; 

ps2 ps2_inst(
     .PS2_DAT_in (PS2_DAT)
    ,.PS2_CLK_in (PS2_CLK)
    ,.clock      (CLOCK_50)
    ,.led_out    (LEDG[7:0])
    ,.down       (down_dir)
    ,.up         (up_dir)
    );

  VGAGenerator vgag0
  (
    .reset(1'b0),    
    .inClock(CLOCK_50),
    .pixelClock(VGA_CLK),
    .rColor(VGA_R),
    .gColor(VGA_G),
    .bColor(VGA_B),
    .hSync(VGA_HS),
    .vSync(VGA_VS),
    .blankN(VGA_BLANK_N),
    .syncN(VGA_SYNC_N),
    .bgColor(SW[2:0]),
    .raket_up   (up_dir),
    .raket_down (down_dir)
  );

endmodule

