// File: cmd_proc.sv
// Author: Trevor Wallis and Tori Schrimpf
`default_nettype none

module cmd_proc(clk,rst_n,cmd,cmd_rdy,clr_cmd_rdy,send_resp,strt_cal,
				cal_done,heading,heading_rdy,lftIR,cntrIR,rghtIR,error,
				frwrd,moving,tour_go,fanfare_go);
				
	parameter FAST_SIM = 1;				// speeds up incrementing of frwrd register for faster simulation
				
	input logic clk,rst_n;					// 50MHz clock and asynch active low reset
	input logic [15:0] cmd;					// command from BLE
	input logic cmd_rdy;						// command ready
	output logic clr_cmd_rdy;			// mark command as consumed
	output logic send_resp;				// command finished, send_response via UART_wrapper/BT
	output logic strt_cal;				// initiate calibration of gyro
	input logic cal_done;						// calibration of gyro done
	input logic signed [11:0] heading;		// heading from gyro
	input logic heading_rdy;					// pulses high 1 clk for valid heading reading
	input logic lftIR;						// nudge error +
	input logic cntrIR;						// center IR reading (have I passed a line)
	input logic rghtIR;						// nudge error -
	output reg signed [11:0] error;		// error to PID (heading - desired_heading)
	output reg [9:0] frwrd;				// forward speed register
	output logic moving;				// asserted when moving (allows yaw integration)
	output logic tour_go;				// pulse to initiate TourCmd block
	output logic fanfare_go;			// kick off the "Charge!" fanfare on piezo
	
	// Move command signal from state machine
	logic move_cmd;
	// Forward control signals from state machine
	logic dec_forward, inc_forward;
	
	// Forward register
	logic [9:0] forward_inc;
	logic enable_forward, max_speed, zero_speed;
	
	assign max_speed = &frwrd[9:8];
	assign zero_speed = &(~frwrd);
	assign enable_forward = heading_rdy ? 	(inc_forward && !max_speed) ? 1'b1 :
											(dec_forward && !zero_speed) ? 1'b1 : 1'b0 : 1'b0;
	
		// Select increment and decrement values based on FAST_SIM
	generate
		if (FAST_SIM)
			assign forward_inc = inc_forward ? 10'h020 : 10'hFC0;
		else
			assign forward_inc = inc_forward ? 10'h004 : 10'hFF8;
	endgenerate
	
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			frwrd <= 10'h000;
		else if (enable_forward)
			frwrd <= frwrd + forward_inc;
	end
	
	// Square counting
	logic move_done;
		//intermediate signals
	logic [2:0] sqr_move;
	logic [3:0] move;
	logic risingEdge;

	always_ff@(posedge clk)
		if(move_cmd)
			sqr_move <= cmd[2:0];
	
	always_ff@(posedge clk) begin
		if(move_cmd)
			move <= '0;
		else if(risingEdge)
			move <= move + 1;
	end
	
		// Edge detector
	reg asynch_cntrIR, synch_cntrIR, synch_cntrIR2;
	always_ff @(posedge clk) begin
		asynch_cntrIR <= cntrIR;
		synch_cntrIR <= asynch_cntrIR;
		synch_cntrIR2 <= synch_cntrIR;
	end
	assign risingEdge = synch_cntrIR & ~synch_cntrIR2;
	assign move_done = ({sqr_move, 1'b0} == move) ? 1'b1 : 1'b0; 
	
	// PID interface
		//intermediate signals
	logic [11:0] next_cmd;
	logic [11:0] desired_heading; 

		//cmd logic
	assign next_cmd = cmd[11:4] == 8'h00 ? {cmd[11:4], 4'h0} : {cmd[11:4], 4'hf};

	always_ff @(posedge clk)
		if(move_cmd)
			desired_heading <= next_cmd;
		
		//nudge logic
	localparam nudgelftdefault = 12'h05f;
	localparam nudgelftfast = 12'h1ff;
	localparam nudgerghtdefault = 12'hfa1;
	localparam nudgerghtfast = 12'he00;
	logic [11:0] err_nudge;
	logic [11:0] nudgelft, nudgerght;

		// Select left and right nudge based on FAST_SIM
	generate
		if (FAST_SIM) begin
			assign nudgelft = nudgelftfast;
			assign nudgerght = nudgerghtfast;
		end
		else begin
			assign nudgelft = nudgelftdefault;
			assign nudgerght = nudgerghtdefault;
		end
	endgenerate
	
	assign err_nudge = ~lftIR ? (~rghtIR ? 12'h000 : nudgerght) : nudgelft;
	assign error = heading - desired_heading + err_nudge;
	
	// Play fanfare set-reset register
	reg playFanfare;
		// Signals to control the value of play fanfare
	logic setPlayFanfare, resetPlayFanfare;
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			playFanfare <= 1'b0;
		else if (resetPlayFanfare)
			playFanfare <= 1'b0;
		else if (setPlayFanfare)
			playFanfare <= 1'b1;
	
	// State machine
	typedef enum reg [2:0] {IDLE, CALIBRATE, ROTATE, COUNT, SLOW} SM_state;
	SM_state state, next_state;
		// Definition of opcodes
	localparam OP_CALABRATE = 4'b0000;
	localparam OP_MOVE = 3'b001; 	// Last bit is don't care for the move command
									// and used later to determine if a fanfare
									// should be played on the completion of a move
	localparam OP_TOUR = 4'b0100;
		// Definition of the maximum allowed heading error before movement starts
	localparam HEADING_THRESHOLD_POS = 12'h030;
	localparam signed HEADING_THRESHOLD_NEG = -HEADING_THRESHOLD_POS;
	
		// Register holding current state
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= next_state;
		
		// State machine logic
	always_comb begin
		// Default state machine outputs
		moving = 1'b0;
		tour_go = 1'b0;
		send_resp = 1'b0;
		clr_cmd_rdy = 1'b0;
		strt_cal = 1'b0;
		fanfare_go = 1'b0;
		move_cmd = 1'b0;
		dec_forward = 1'b0;
		inc_forward = 1'b0;
		resetPlayFanfare = 1'b0;
		setPlayFanfare = 1'b0;
		next_state = state;
		case (state)
			CALIBRATE: begin
				if (cal_done) begin
					send_resp = 1'b1;
					next_state = IDLE;
				end
			end
			ROTATE: begin
				moving = 1'b1;
				if (error <= HEADING_THRESHOLD_POS && error >= HEADING_THRESHOLD_NEG)
					next_state = COUNT;
			end
			COUNT: begin
				inc_forward = 1'b1;
				moving = 1'b1;
				if (move_done) begin
					if (playFanfare) begin
						resetPlayFanfare = 1'b1;
						fanfare_go = 1'b1;
					end
					next_state = SLOW;
				end
			end
			SLOW: begin
				dec_forward = 1'b1;
				moving = 1'b1;
				if (zero_speed) begin
					send_resp = 1'b1;
					next_state = IDLE;
				end
			end
			// Defaults to IDLE state
			default: begin
				if (cmd_rdy) begin
					if (cmd[15:12] == OP_CALABRATE) begin
						clr_cmd_rdy = 1'b1;
						strt_cal = 1'b1;
						next_state = CALIBRATE;
					end
					else if (cmd[15:12] == OP_TOUR) begin
						clr_cmd_rdy = 1'b1;
						tour_go = 1'b1;
					end
					else if (cmd[15:13] == OP_MOVE) begin
						if (cmd[12] == 1'b1)
							setPlayFanfare = 1'b1;
						clr_cmd_rdy = 1'b1;
						move_cmd = 1'b1;
						next_state = ROTATE;
					end
				end
			end
		endcase
	end	
endmodule
`default_nettype wire