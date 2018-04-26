module main(
  input CLOCK_50 // 50 MHz

 ,input [3:0]KEY

 ,input [2:0]SW

 ,input PS2_CLK
 ,input PS2_DAT

 ,output [8:0] LEDG

 ,output VGA_VS     // VGA_VSYNC 
 ,output VGA_HS     // VGA_HSYNC 
 ,output [7:0]VGA_R // [4:0] VGA_RED
 ,output [7:0]VGA_G // [4:0] VGA_GREEN
 ,output [7:0]VGA_B // [4:0] VGA_BLUE

 ,output VGA_CLK
 ,output VGA_SYNC_N
 ,output VGA_BLANK_N
 
 ,output test_point 
);

//assign VGA_SYNC_N = 1'b0;

/*wire [2:0]  clk_div; 
assign test_point = clk_div[2];
lpm_counter1 lpm_counter1_inst(
     .clock (CLOCK_50)
    ,.q     (clk_div)
    );*/

//wire [3:0]key;
wire up_dir, down_dir; 
//assign key[3]     = KEY[0];  // reset

ps2 ps2_inst(
     .PS2_DAT_in (PS2_DAT)
    ,.PS2_CLK_in (PS2_CLK)
    ,.clock      (CLOCK_50)
    ,.led_out    (LEDG[7:0])
    ,.down       (down_dir)
    ,.up         (up_dir)
    );

/*wire [7:0]  char_count;
wire [11:0] line_count;
wire pre_visible;
hvsync hvsync_inst(
     .reset       (1'h0)
    ,.char_clock  (clk_div[2])
    ,.char_count  (char_count)
    ,.line_count  (line_count)    
    ,.hsync       (VGA_HSYNC)
    ,.vsync       (VGA_VSYNC)
    ,.pre_visible (pre_visible)	
     );*/


/*wire [7:0]goals;
wire video_r;
wire video_g;
wire video_b;
*/

//assign VGA_R = {8{video_r}};
//assign VGA_G = {8{video_g}};
//assign VGA_B = {8{video_b}};

/*assign VGA_RED = {5{video_r}};
assign VGA_GREEN = {5{video_g}};
assign VGA_BLUE = {5{video_b}};*/

/*assign VGA_RED[1] = video_r;
assign VGA_RED[2] = video_r;
assign VGA_RED[3] = video_r;
assign VGA_RED[4] = video_r;*/

/*game game_inst(
     .char_clock  (clk_div[2])
    ,.vsync       (VGA_VSYNC)
    ,.key         (key)
    ,.char_count  (char_count)
    ,.line_count  (line_count) 
    ,.pre_visible (pre_visible)
    ,.video       ()
    ,.video_r     (video_r)
    ,.video_g     (video_g)
    ,.video_b     (video_b)
    ,.goals       (goals)
     );*/

  //localparam MIC_WORD_SIZE = 16;
  wire sampleRate;
  reg [9:0] fftSampleNumber;
  reg [9:0] fftOutData;
 //reg [MIC_WORD_SIZE-1:0] fftInDataAbs, fftOutData;    

assign sampleRate = CLOCK_50;

always @(posedge CLOCK_50) begin
  if (fftSampleNumber < 10'b11_1111_1111) begin
    fftSampleNumber <= fftSampleNumber + 1;
    fftOutData <= fftSampleNumber;
  end  
end

  VGAGenerator vgag0
  (
    //.reset(~configReady),
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
    .vramWriteClock(sampleRate),
    .vramWriteAddr(fftSampleNumber),
    .vramInData (fftOutData),
    .raket_up   (up_dir),
    .raket_down (down_dir)
  );

endmodule

