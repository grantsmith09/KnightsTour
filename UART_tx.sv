// File: UART_tx.sv
// Description: Handles transmitting 8-bits over the UART transmission protocol
// Author: Trevor Wallis
`default_nettype none

module UART_tx(clk, rst_n, trmt, tx_data, tx_done, TX);

input logic clk, rst_n, trmt;
input logic [7:0] tx_data;
output logic TX;
output reg tx_done;

typedef enum reg {IDLE, TRANSMITTING} SM_state;
logic init, shift, set_done, transmitting;
logic [8:0] tx_shift_reg_in;
logic [3:0] bit_cnt_in;
reg [8:0] tx_shift_reg;
reg [3:0] bit_cnt;
reg [11:0] baud_cnt;
SM_state state, next_state;

// Transmitter shifter
assign tx_shift_reg_in = 	(init) ? ({tx_data, 1'b0}) :
							(shift) ? ({1'b1, tx_shift_reg[8:1]}) :
							(tx_shift_reg);
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		tx_shift_reg <= 9'hfff;
	else
		tx_shift_reg <= tx_shift_reg_in;
end
assign TX = tx_shift_reg[0];

// Baud counter
always_ff @(posedge clk) begin
	if (init | shift)
		baud_cnt <= 12'h000;
	else if (transmitting)
		baud_cnt <= baud_cnt + 1;
	else
		baud_cnt <= baud_cnt;
end
assign shift = (baud_cnt >= 12'hA2C) ? 1 : 0;

// Bit counter
assign bit_cnt_in = (init) ? (4'h0) :
					(shift) ? (bit_cnt + 1) :
					(bit_cnt);
always_ff @(posedge clk) begin
	bit_cnt <= bit_cnt_in;
end

// State machine
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= next_state;
end
always_comb begin
	// Default conditions
	next_state = state;
	init = 1'b0;
	set_done = 1'b0;
	transmitting = 1'b0;
	case(state)
		TRANSMITTING: begin
			if (bit_cnt == 4'hA) begin
				next_state = IDLE;
				set_done = 1'b1;
			end else
				transmitting = 1'b1;
				
		end
		// Defaults to the idle state
		default: begin
			if (trmt) begin
				next_state = TRANSMITTING;
				init = 1'b1;
			end
		end
	endcase
end

// Transmission done signal
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		tx_done <= 1'b0;
	else if (init)
		tx_done <= 1'b0;
	else if (set_done)
		tx_done <= 1'b1;
end

endmodule
`default_nettype wire
