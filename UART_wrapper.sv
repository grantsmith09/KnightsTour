// File: UART_wrapper.sv
// Description: Packages two bytes of recieved data into a single command
// Author: Trevor Wallis
`default_nettype none

module UART_wrapper(clr_cmd_rdy, cmd_rdy, cmd, trmt, resp, tx_done, clk, rst_n, RX, TX);

input logic clr_cmd_rdy, trmt, clk, rst_n, RX;
input logic [7:0] resp;
output logic TX, tx_done;
output reg cmd_rdy;
output logic [15:0] cmd;

logic rx_rdy, clr_rdy, first_byte_in, set_cmd_rdy, rst_cmd_rdy;
logic [7:0] rx_data;
reg [7:0] first_byte;
typedef enum reg {IDLE, COMMUNICATING} SM_state;
SM_state state, next_state;

UART UART(.clk(clk),.rst_n(rst_n),.RX(RX),.TX(TX),.rx_rdy(rx_rdy),.clr_rx_rdy(clr_rdy),.rx_data(rx_data),.trmt(trmt),.tx_data(resp),.tx_done(tx_done));

// First byte flip-flop
always_ff @(posedge clk) begin
	if (first_byte_in)
		first_byte <= rx_data;
end

// State machine
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= next_state;
end
always_comb begin
	next_state = state;
	clr_rdy = 1'b0;
	set_cmd_rdy = 1'b0;
	first_byte_in = 1'b0;
	case (state)
		COMMUNICATING: begin
			if (rx_rdy) begin
				next_state = IDLE;
				set_cmd_rdy = 1'b1;
				clr_rdy = 1'b1;
			end
		end
		// Defaults to IDLE state
		default: begin
			if (rx_rdy) begin
				next_state = COMMUNICATING;
				clr_rdy = 1'b1;
				first_byte_in = 1'b1;
			end
		end
	endcase
end

// Command ready signal
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		cmd_rdy <= 1'b0;
	else if (set_cmd_rdy)
		cmd_rdy <= 1'b1;
	else if (clr_cmd_rdy | trmt | clr_rdy)
		cmd_rdy <= 1'b0;
end

// Construction of command signal
assign cmd = {first_byte, rx_data};

endmodule
`default_nettype wire