// File: TourCmd.sv
// Description: Converts the moves passed by TourLogic into commands for the robot
// Author: Trevor Wallis and Tori Schrimpf
`default_nettype none

module TourCmd(clk, rst_n, start_tour, mv_indx, move, cmd_UART, cmd_rdy_UART, cmd, cmd_rdy, clr_cmd_rdy, send_resp, resp);

input logic clk, rst_n, start_tour, cmd_rdy_UART, clr_cmd_rdy, send_resp;
input logic [7:0] move;
input logic [15:0] cmd_UART;
output logic cmd_rdy;
output logic [4:0] mv_indx;
output logic [15:0] cmd;
output logic [7:0] resp;

// Move index controller
	logic increment_index, reset_index; // Controlling signals from state machine
	always_ff @(posedge clk)
		if (reset_index)
			mv_indx <= '0;
		else if (increment_index)
			mv_indx <= mv_indx + 1;

// Decompose move command
	// cmd[15:12]	opcode
	// cmd[12]		high for charge
	// cmd[11:4]	heading
	// cmd[3:0]		number of squares for move
	logic [15:0] cmd_decomopsed, move_horizontal, move_veritcal;
	logic cmd_control; // Low when a horizontal move is occuring
	// Heading options
	localparam NORTH = 8'h00;
	localparam EAST = 8'hbf;
	localparam SOUTH = 8'h7f;
	localparam WEST = 8'h3f;
	// Horizontal move is assumed to be the first move so a fanfare is not played
	assign move_horizontal = 	(move[0] || move[4]) ? {4'b0010, WEST, 4'b0001} :
								(move[1] || move[5]) ? {4'b0010, EAST, 4'b0001} :
								(move[2] || move[3]) ? {4'b0010, WEST, 4'b0010} :
								{4'b0010, EAST, 4'b0010};
	assign move_veritcal = 		(move[0] || move[1]) ? {4'b0011, NORTH, 4'b0010} :
								(move[2] || move[7]) ? {4'b0011, NORTH, 4'b0001} :
								(move[3] || move[6]) ? {4'b0011, SOUTH, 4'b0001} :
								{4'b0011, SOUTH, 4'b0010};
	assign cmd_decomopsed = cmd_control ? move_veritcal : move_horizontal;

// Select output command and command ready signal
	logic cmd_rdy_sm; // Command ready signal from state machine
	logic select_UART; // High when the UART's values are being passed through
	assign cmd = (select_UART) ? cmd_UART : cmd_decomopsed;
	assign cmd_rdy = (select_UART) ? cmd_rdy_UART : cmd_rdy_sm;
	
//Resp Control
assign resp = select_UART ? 8'hA5 : 8'h5A;


// State machine
	// Register for holding current state
	typedef enum reg [2:0] {IDLE, HORIZ_LOAD, HORIZ_MV, VERT_LOAD, VERT_MV, BUFFER} SM_state;
	SM_state state, next_state;
	
	always_ff@(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= next_state;
	
	// State Machine logic
	always_comb begin
		cmd_rdy_sm = 0;
		select_UART = 0;
		increment_index = 0;
		reset_index = 0;
		next_state = state;
		cmd_control = 0;
		case (state)
			HORIZ_LOAD: begin
				cmd_rdy_sm = 1;
				if(clr_cmd_rdy)
					next_state = HORIZ_MV;
			end
			HORIZ_MV: begin
				if(send_resp) begin
					next_state = VERT_LOAD;
				end
			end
			VERT_LOAD : begin
				cmd_rdy_sm = 1;
				cmd_control = 1;
				if(clr_cmd_rdy)
					next_state = VERT_MV;
			end
			VERT_MV : begin
				cmd_control = 1;
				if(send_resp && mv_indx == 5'd23) begin
					select_UART = 1;
					next_state = IDLE;
				end
				else if(send_resp) begin
					increment_index = 1;
					next_state = BUFFER;
				end
			end
			BUFFER : begin
				next_state = HORIZ_LOAD;
			end
			// Defaults to the idle state
			default: begin
				select_UART = 1;
				if(start_tour) begin
					reset_index = 1;
					select_UART = 0;
					next_state = BUFFER;
				end
			end
		endcase
	end
endmodule
`default_nettype wire