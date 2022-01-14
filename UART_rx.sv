// File: UART_rx.sv
// Description: Recieves serial data over the UART protocol to send a command to the logic analyzer
// Author: Trevor Wallis
`default_nettype none

module UART_rx(clk, rst_n, RX, rdy, rx_data, clr_rdy);

input logic clk, rst_n, clr_rdy, RX;
output logic [7:0] rx_data;
output logic rdy;

typedef enum reg {IDLE, RECEIVING} SM_state;
logic start, shift, set_rdy, receiving;
logic [8:0] rx_shift_reg_in;
logic [3:0] bit_cnt_in;
reg [8:0] rx_shift_reg;
reg [3:0] bit_cnt;
reg [11:0] baud_cnt;
reg RX_1, RX_Stable, RX_Previous;
SM_state state, next_state;

// Double flop RX to remove meta-stability
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		RX_1 <= 1'b1;
		RX_Stable <= 1'b1;
		RX_Previous <= 1'b1;
	end else begin
		RX_1 <= RX;
		RX_Stable <= RX_1;
		RX_Previous <= RX_Stable;
	end
end

// Reciever shifter
assign rx_shift_reg_in = (shift) ? ({RX_Stable, rx_data[7:1]}) : rx_data;
always_ff @(posedge clk) begin
	rx_shift_reg <= rx_shift_reg_in;
end
assign rx_data = rx_shift_reg[7:0];

// Baud counter
always_ff @(posedge clk) begin
	if (start)
		baud_cnt <= 12'h516;
	else if (shift)
		baud_cnt <= 12'hA2C;
	else if (receiving)
		baud_cnt <= baud_cnt - 1;
	else
		baud_cnt <= baud_cnt;
end
assign shift = (baud_cnt == 12'h000) ? 1 : 0;

// Bit counter
assign bit_cnt_in = (start) ? (4'h0) :
					(shift) ? (bit_cnt + 1) :
					(bit_cnt);
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		bit_cnt <= 4'h0;
	else
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
	receiving = 1'b0;
	start = 1'b0;
	set_rdy = 1'b0;
	case(state)
		RECEIVING: begin
			if (bit_cnt == 4'h9) begin
				next_state = IDLE;
				set_rdy = 1'b1;
			end else
				receiving = 1'b1;
		end
		// Defaults to the idle state
		default: begin
			if (!RX_Stable && RX_Previous) begin
				next_state = RECEIVING;
				start = 1'b1;
			end
		end
	endcase
end

// Reciever ready signal
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		rdy <= 1'b0;
	else if (start)
		rdy <= 1'b0;
	else if (clr_rdy)
		rdy <= 1'b0;
	else if (set_rdy)
		rdy <= 1'b1;
end

endmodule
`default_nettype wire
