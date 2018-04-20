
///////////////////////////////////////////////////////////////
//module which generates video sync impulses
///////////////////////////////////////////////////////////////

module hvsync (
	// inputs:
	input wire reset,
	input wire char_clock,
	
	// outputs:
	output reg [7:0]char_count,
	output reg [11:0]line_count,
	output reg hsync,
	output reg vsync,
	output reg pre_visible
	);

//calculate visible screen area
always @*
begin
	pre_visible = ((char_count==131)|(char_count<99)) & (line_count<600);
end

//synchronous process
always @(posedge char_clock or posedge reset)
begin
	if(reset)
	begin
		hsync <= 1'b0;
		char_count <= 0;
	end
	else
	begin
		hsync <= (char_count >= 104) & (char_count < 120);
		if(char_count == 131)
			char_count <= 0;
		else
			char_count <= char_count + 1'b1;
	end
end

always @(posedge char_clock or posedge reset)
begin
	if(reset)
	begin
		vsync <= 1'b0;
		line_count <= 0;
	end
	else
	if(char_count == 104)
	begin
		vsync <= (line_count >= 600) & (line_count < 604);
		if(line_count == 627)
			line_count <= 0;
		else
			line_count <= line_count + 1'b1;
	end
end

endmodule

