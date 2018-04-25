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
	input vramWriteClock,
	input signed [9:0] vramWriteAddr,
	input signed [9:0] vramInData
);

	localparam Y_OFFSET = 768;

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
	localparam LEFT_RAKET_POSITION = H_MAX_POSITION - H_RIGHT_RAKET_OFFSET - H_SIZE_RAKET;
	localparam RIGHT_RAKET_POSITION = H_MAX_POSITION - H_RIGHT_RAKET_OFFSET;

	wire vgaClock, blank;
	wire [23:0] bgFullColor;
	reg [23:0] fullColor;
	wire [9:0] xActivePixel, yActivePixel;
	wire signed [9:0] yActivePixelPos, vramOutData;

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
		.c0(pixelClock)
	);
	
	VideoRAM vram0
	(
		.data(vramInData),
		.rdaddress(xActivePixel),
		.rdclock(pixelClock),
		.wraddress(vramWriteAddr),
		.wrclock(vramWriteClock),
		.wren(1'b1),
		.q(yActivePixelPos)
	);
	
	reg border;
	reg raket;



	always @(posedge pixelClock or posedge reset)
	begin
		if (reset)
		begin
			//fullColor <= 1'b0;

			border <= 1'b0;
		end
	
		else
		begin
		    //fullColor <= {3{xActivePixel[9:2]^yActivePixel[9:2]}};

			//if (Y_OFFSET - yActivePixelPos <= yActivePixel) fullColor <= ~bgFullColor;
			//else fullColor <= bgFullColor;

			// border	
			//fullColor <= {23{(xActivePixel < 16) | (xActivePixel > (1024-16)) | (yActivePixel < 16) | (yActivePixel > (768-16))}};
			
			// border
			border <= (xActivePixel < 16) | (xActivePixel > (1024-16)) | (yActivePixel < 16) | (yActivePixel > (768-16));
		end

	end




	reg raket_x;
	reg raket_y;

	always @(posedge pixelClock or posedge reset)
	begin
			raket_x <= (xActivePixel >= LEFT_RAKET_POSITION) & (xActivePixel <= RIGHT_RAKET_POSITION); 
			raket_y <= (yActivePixel >= H_MIN_POSITION) & (yActivePixel <= H_MIN_POSITION + V_SIZE_RAKET);	
			raket <= raket_x & raket_y;		
	end

	always @* //(posedge pixelClock or posedge reset)
	begin
		if (raket) fullColor <= 24'hffffff; //24'b1111_1111_1111_1111; //{16{1'b1}};
		if (border) fullColor <= 24'h00ffff; //16'b1111_1111_1111_1111; //  {22{1'b1}};
		if ((!raket) & (!border)) fullColor <= 24'h000000;  //{24{1'b0}};
			
		//fullColor <= {22{ raket | border}};
	
	end

endmodule
