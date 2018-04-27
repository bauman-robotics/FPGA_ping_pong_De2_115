module ps2(input PS2_DAT_in,
           input PS2_CLK_in,
           input clock,
           output reg [7:0] led_out_g,
           output [7:0] led_out_r,              
           output reg down,
           output reg up);

reg 		keyready;
reg [2:0]	kr;
reg [7:0]	keycode_o;
reg  	    key_release;

reg up_press;
reg down_press;
reg left_press;
reg right_press;
reg space_press;

assign led_out_r[0] = up_press;
assign led_out_r[1] = down_press;
assign led_out_r[2] = left_press;
assign led_out_r[3] = right_press;
assign led_out_r[4] = space_press;

always @(posedge clock) begin
		if      ((up_press)   && (~down_press)) begin up <= 1; down <= 0; end
		else if ((down_press) && (~up_press))   begin up <= 0; down <= 1; end
		else 									begin up <= 0; down <= 0; end 
end

always @(negedge PS2_CLK_in) keyready <= (revcnt[3:0]==10); // получили 10 бит из 11 битного пакета
// когда мы получим 11 бит пакета, keyready будет равен 0.
always @(posedge clock) begin
	kr <= {kr,keyready};
	if (kr[1]&&~kr[2]) begin  // небыло данных, потом получили 10 бит, затем пришло что-то ещё (11 бит),
	                          // важно, что в старшем разряде - 0, а в следующем - 1 
		led_out_g   <= keycode_o;			  
		key_release <= keycode_o == 8'hF0;

		case (keycode_o)
			8'h75: up_press    <= ~key_release;
			8'h72: down_press  <= ~key_release;
			8'h6B: left_press  <= ~key_release;
			8'h74: right_press <= ~key_release;
			8'h29: space_press <= ~key_release;
		endcase
	end  
end
	
reg   ps2_clk_in, ps2_clk_syn1, ps2_dat_in, ps2_dat_syn1;
wire  clk;

//clk division, derive a 97.65625KHz clock from the 50MHz source;
reg [8:0] clk_div;
always@(posedge clock) clk_div <= clk_div+1'b1;
assign clk = clk_div[8];

//multi-clock region simple synchronization
always@(posedge clk) begin
	ps2_clk_syn1 <= PS2_CLK_in;
	ps2_clk_in   <= ps2_clk_syn1;

	ps2_dat_syn1 <= PS2_DAT_in;
	ps2_dat_in   <= ps2_dat_syn1;
end

reg	[7:0]	revcnt;
	
always @( posedge ps2_clk_in) begin
	if (revcnt >=10) revcnt <= 0;
	else             revcnt <= revcnt + 1'b1;
end
	
always @(posedge ps2_clk_in) begin
	case (revcnt[3:0])
		2: keycode_o[0] <= ps2_dat_in;
		3: keycode_o[1] <= ps2_dat_in;
		4: keycode_o[2] <= ps2_dat_in;
		5: keycode_o[3] <= ps2_dat_in;
		6: keycode_o[4] <= ps2_dat_in;
		7: keycode_o[5] <= ps2_dat_in;
		8: keycode_o[6] <= ps2_dat_in;
		9: keycode_o[7] <= ps2_dat_in;
	endcase
end
endmodule