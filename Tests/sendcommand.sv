// Command opcodes
localparam OP_CALABRATE = 4'b0000;
localparam OP_MOVE = 4'b0010;
localparam OP_MOVE_FANFARE = 4'b0011;
localparam OP_TOUR = 4'b0100;

// Headings
localparam NORTH = 8'h00;
localparam EAST = 8'hbf;
localparam SOUTH = 8'h7f;
localparam WEST = 8'h3f;

// Calibrate the knight
task automatic calibrate(ref clk, ref send_cmd, ref reg [15:0] cmd);
	cmd = {OP_CALABRATE, 12'h000};
	send_cmd = 1;
	@(posedge clk);
	send_cmd = 0;
endtask

// Move commands
task automatic move(input [7:0] heading, input [3:0] squares, ref clk, ref reg [15:0] cmd, ref send_cmd);
	@(posedge clk);
	cmd = {OP_MOVE, heading, squares};
	send_cmd = 1;
	@(posedge clk);
	send_cmd = 0;
endtask

task automatic moveFanfare(input [7:0] heading, input [3:0] squares, ref clk, ref reg [15:0] cmd, ref send_cmd);
	@(posedge clk);
	cmd = {OP_MOVE_FANFARE, heading, squares};
	send_cmd = 1;
	@(posedge clk);
	send_cmd = 0;
endtask

// Tour options
task automatic tourCenter(ref clk, ref reg [15:0] cmd, ref send_cmd);
	repeat(2)@(posedge clk);
	cmd = {OP_TOUR, 4'bxxxx, 4'b0010, 4'b0010};
	send_cmd = 1;
	@(posedge clk);
	send_cmd = 0;
endtask

task automatic tourBottomLeft(ref clk, ref reg [15:0] cmd, ref send_cmd, ref logic [14:0] knightXX, ref logic [14:0] knightYY);
	knightXX = 15'h0800;
	knightYY = 15'h0800;
	repeat(2)@(posedge clk);
	cmd = {OP_TOUR, 4'bxxxx, 4'b0000, 4'b0000};
	send_cmd = 1;
	@(posedge clk);
	send_cmd = 0;
endtask