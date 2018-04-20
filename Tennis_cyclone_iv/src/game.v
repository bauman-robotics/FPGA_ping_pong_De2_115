
///////////////////////////////////////////////////////////////
//module which generates video sync impulses
///////////////////////////////////////////////////////////////

module game(
	// inputs:
	input wire char_clock,
	input wire vsync,

	input wire [3:0]key,
	
	// outputs:
	input wire [7:0]char_count,
	input wire [11:0]line_count,
	input wire pre_visible,

	output reg video,
	output reg video_r,
	output reg video_g,
	output reg video_b,
	output reg [7:0]goals
	);

reg [6:0]x;
reg dx;
reg [6:0]y;
reg dy;

reg [1:0]counter;
wire tm; assign tm = counter[1];

always @(posedge vsync)
begin
	if(counter==2)
		counter<=0;
	else
		counter <= counter+1'b1;
end

reg border;
always @*
	border = (char_count[7:1]==0)|(char_count==131)|(line_count[11:4]==0)|(line_count[11:4]>=36);

reg [7:0]ry;
reg raket;
always @*
	raket = (char_count[7:1]==47)&(ry<line_count[11:4])&((ry+6)>line_count[11:4]);

always @(posedge tm)
begin
 case (1'b0)
  key[0] : if (ry> 0) ry<=ry-1'b1;
  key[1] : if (ry<30) ry<=ry+1'b1;
 endcase
end


always @(posedge tm or negedge key[3])
begin
	if(!key[3])
	begin
		//reset
		goals <= 0;
		x<=20;
		y<=20;
	end
	else
	begin
		if(goals!=8'b11111111)
		begin
			if(dx==1'b0)
			begin
				x <= x+1'b1;
				if( (x==45)&&(y>ry)&&(y<ry+6) )
				begin
					//raket
					dx<=1'b1;
				end
				else
				if(x>47)
				begin
					//goal
					goals<={goals[6:0],1'b1};
					dx<=1'b1;
				end
			end
			else
			begin
				x <= x-1'b1;
				if(x==2)
					dx<=1'b0;
			end

			if(dy==1'b0)
			begin
				y <= y+1'b1;
				if(y>33)
					dy<=1'b1;
			end
			else
			begin
				y <= y-1'b1;
				if(y==2)
					dy<=1'b0;
			end
		end
	end
end

wire ball; assign ball = ((char_count[7:1]==x)&(line_count[11:4]==y));

always @(posedge char_clock)
begin
	video_r <= pre_visible & ball;
	video_g <= pre_visible & (border|raket);
	video_b <= pre_visible ^ ( (border|raket|ball) & pre_visible);
	video   <= (ball|border|raket)&pre_visible;
end
	
endmodule

