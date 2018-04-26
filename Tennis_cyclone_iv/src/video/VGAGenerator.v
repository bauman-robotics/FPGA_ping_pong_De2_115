/*
*
* Copyright (c) 2015 Goshik (goshik92@gmail.com)
*
*
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* 
*/

module VGAGenerator
(
	input reset,
	input inClock,
	output pixelClock,
	output [7:0] rColor,
	output [7:0] gColor,
	output [7:0] bColor,
	output hSync,
	output vSync,
	output blankN,
	output syncN,
	input [2:0] bgColor,
	input raket_up,
	input raket_down
);

	localparam H_VISIBLE_AREA = 1024;
	localparam V_VISIBLE_AREA = 768;
	localparam H_BORDER_SIZE = 16;
	localparam V_BORDER_SIZE = 16;

	localparam H_MIN_POSITION = H_BORDER_SIZE;
	localparam H_MAX_POSITION = H_VISIBLE_AREA - V_BORDER_SIZE;	
	localparam V_MIN_POSITION = V_BORDER_SIZE;
	localparam V_MAX_POSITION = V_VISIBLE_AREA - V_BORDER_SIZE;	

	localparam V_SIZE_RAKET = 96; 
	localparam H_SIZE_RAKET = 16; 
	localparam H_RIGHT_RAKET_OFFSET = 16;
	localparam LEFT_RAKET_POSITION  = H_MAX_POSITION - H_RIGHT_RAKET_OFFSET - H_SIZE_RAKET;
	localparam RIGHT_RAKET_POSITION = H_MAX_POSITION - H_RIGHT_RAKET_OFFSET;

	localparam V_RAKET_MIN_POS = V_MIN_POSITION;
	localparam V_RAKET_MAX_POS = V_MAX_POSITION - V_SIZE_RAKET;

	wire vgaClock, blank;
	wire [23:0] bgFullColor;
	reg  [23:0] fullColor;
	wire [9:0] xActivePixel, yActivePixel;

	assign bgFullColor = {{8{bgColor[0]}}, {8{bgColor[1]}}, {8{bgColor[2]}}};
	assign {rColor, gColor, bColor} = fullColor;
	assign syncN = 1'b0;
	assign blankN = ~blank;

	VGASyncGenerator vgasg0
	(
		.reset(reset),
		.inClock(pixelClock),
		.vSync(vSync),
		.hSync(hSync),
		.blank(blank),
		.xPixel(xActivePixel),
		.yPixel(yActivePixel)
	);
	
	VGAClockSource vgacs0
	(
		.areset(reset),
		.inclk0(inClock),
		.c0(pixelClock)  // (50/2) * 3 = 75 MHz
	);
	
 	// Border paint
	reg border; 	
	always @(posedge pixelClock or posedge reset)
	begin
		border <= (xActivePixel < H_BORDER_SIZE) | 
				  (xActivePixel > (H_VISIBLE_AREA-H_BORDER_SIZE)) | 
				  (yActivePixel < V_BORDER_SIZE) | 
				  (yActivePixel > (V_VISIBLE_AREA-V_BORDER_SIZE));
	end
	//---------------------------

	// Raket paint
	reg raket_x;
	reg raket_y;
	reg raket;
	always @(posedge pixelClock or posedge reset)
	begin
			raket_x <= (xActivePixel >= LEFT_RAKET_POSITION) & 
					   (xActivePixel <= RIGHT_RAKET_POSITION); 
			raket_y <= (yActivePixel >= V_RAKET_MIN_POS + raket_y_var_pos) & 
					   (yActivePixel <= V_RAKET_MIN_POS + raket_y_var_pos + V_SIZE_RAKET);	
			raket <= raket_x & raket_y;		
	end
	//---------------------------	

    always @* 
    begin
        if (raket)  fullColor <= {24{1'b1}};                            // 24'hffffff
        if (border) fullColor <= {16{1'b1}};                            // 24'h00ffff; 
        if (ball)   fullColor <= {{8{8'hf0}}, {8{8'hf0}}, {8{8'hff}}};      // 24'hf0f0f0;
        if ((!raket) && (!border) && (!ball)) fullColor <= bgFullColor; // {24{1'b0}} // 24'h000000; 
    end
	//---------------------------	

	// Raket movement
	reg [0:16]counter;        // for clk div
	always @(posedge pixelClock) counter <= counter + 1;	

	reg [9:0]raket_y_var_pos;   // [0 - (V_RAKET_MAX_POS - V_RAKET_MIN_POS)]
	wire clkStb; assign clkStb = &counter; // all in hi level 

	always @(posedge pixelClock) if (clkStb) begin
		if ((raket_up) && (raket_y_var_pos > 0))  
			raket_y_var_pos <= raket_y_var_pos - 1;
		else if ((raket_down) && (raket_y_var_pos < (V_RAKET_MAX_POS - V_RAKET_MIN_POS))) 
			raket_y_var_pos <= raket_y_var_pos + 1;
	end

	//---------------------------
	// Ball
	//---------------------------


    // Ball moving by X
	reg dx; // if (dx==0)  => x <= x + 1; // if (dx==1) => x <= x -1;    
	reg [9:0]ball_x_pos;
	always @(posedge pixelClock) if (clkStb) begin
		if (dx == 0) begin // if moving to right 
			if ((ball_x_pos + BALL_RADIUS == LEFT_RAKET_POSITION) &&   // if ball meet whis raket
				(ball_y_pos - BALL_RADIUS > raket_y_var_pos) && 
				(ball_y_pos + BALL_RADIUS < raket_y_var_pos + V_SIZE_RAKET))
			dx = 1;	
			else if (ball_x_pos + BALL_RADIUS < H_MAX_POSITION) ball_x_pos <= ball_x_pos + 1;
			else dx = 1;     // if moving to left 
		end
		else begin  // if (dx == 1)
			if (ball_x_pos - BALL_RADIUS > H_MIN_POSITION ) ball_x_pos <= ball_x_pos - 1;
			else dx = 0;	
		end
	end

    // Ball moving by Y
	reg dy; // if (dy==0)  => y <= y + 1; // if (dy==1) => y <= y -1;
	reg [9:0]ball_y_pos;
	always @(posedge pixelClock) if (clkStb) begin
		if (dy == 0) begin // if moving to right 
			if (ball_y_pos + BALL_RADIUS < V_MAX_POSITION) ball_y_pos <= ball_y_pos + 1;
			else dy = 1;     // if moving to left 
		end
		else begin  // if (dx == 1)
			if (ball_y_pos - BALL_RADIUS > V_MIN_POSITION ) ball_y_pos <= ball_y_pos - 1;
			else dy = 0;	
		end
	end

    // Ball paint cirle
    reg ball;
    localparam BALL_RADIUS = 12;
	always @(posedge pixelClock or posedge reset)
	begin
		ball <= (xActivePixel - ball_x_pos) ** 2  + (yActivePixel - ball_y_pos) ** 2 < BALL_RADIUS ** 2;				
	end

endmodule
