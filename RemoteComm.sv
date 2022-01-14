module RemoteComm(clk, rst_n, RX, TX, cmd, send_cmd, cmd_sent, resp_rdy, resp);

input clk, rst_n;		// clock and active low reset
input RX;				// serial data input
input logic send_cmd;			// indicates to tranmit 24-bit command (cmd)
input [15:0] cmd;		// 16-bit command

output TX;				// serial data output
output logic cmd_sent;		// indicates transmission of command complete
output resp_rdy;		// indicates 8-bit response has been received
output [7:0] resp;		// 8-bit response from DUT

wire [7:0] tx_data;		// 8-bit data to send to UART
wire tx_done;			// indicates 8-bit was sent over UART
wire rx_rdy;			// indicates 8-bit response is ready from UART

///////////////////////////////////////////////
// Registers needed...state machine control //
/////////////////////////////////////////////
					// used to buffer low byte of cmd

logic [7:0] lowbuffer; //low byte buffer
logic sel; //select
logic trmt; //transmit
logic set_cmd_snt; //set command sent
					
always_ff@(posedge clk, posedge send_cmd)
	if(send_cmd)
		lowbuffer <= cmd[7:0];
	else
		lowbuffer <= lowbuffer;
		
assign tx_data = sel? cmd[15:8] : lowbuffer;

		
///////////////////////////////
// state definitions for SM //
/////////////////////////////

typedef enum reg [1:0] {IDLE, HIGH, LOW} state_t;
state_t state, nxt_state;

///////////////////////////////////////////////
// Instantiate basic 8-bit UART transceiver //
/////////////////////////////////////////////
UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(tx_data), .trmt(trmt),
           .tx_done(tx_done), .rx_data(resp), .rx_rdy(resp_rdy), .clr_rx_rdy(resp_rdy));
		   
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
		
always_comb begin
//default values
sel = 1'b1;
trmt = 1'b0;
set_cmd_snt = 1'b0;
nxt_state = state;

case(state)
	IDLE:
		if(send_cmd) begin
			trmt = 1'b1;
			nxt_state = HIGH;
		end
	HIGH:
		if(tx_done) begin
			sel = 1'b0;
			trmt = 1'b1;
			nxt_state = LOW;
		end
	LOW:
		if(tx_done) begin
			set_cmd_snt = 1'b1;
			nxt_state = IDLE;
		end
endcase

end
		
//command sent logic
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		cmd_sent <= 1'b0;
	else if(send_cmd)
		cmd_sent <= 1'b0;
	else if (set_cmd_snt)
		cmd_sent = 1'b1;
	else
		cmd_sent <= cmd_sent;


endmodule	
