// File: UART_tb.sv
// Description: Tests the functionallity of the UART transmitter and reciever
// Author: Trevor Wallis
`default_nettype none

module UART_tb();

reg clk, test_passed, trmt, rst_n, clr_rdy;
reg [7:0] tx_data;
logic TX_RX, tx_done, rdy;
logic [7:0] rx_data;

UART_tx iDUT_tx(.clk(clk), .rst_n(rst_n), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done), .TX(TX_RX));
UART_rx iDUT_rx(.clk(clk), .rst_n(rst_n), .RX(TX_RX), .rdy(rdy), .rx_data(rx_data), .clr_rdy(clr_rdy));

initial begin
	// Initialize the UART
	clk = 0;
	test_passed = 1;
	tx_data = 8'h75;
	rst_n = 1'b0;
	trmt = 1'b0;
	clr_rdy = 1'b0;
	@(posedge clk);
	@(negedge clk);
	rst_n = 1'b1;
	@(posedge clk);
	
	// Test transmitting data
	trmt = 1'b1;
	@(posedge clk);
	trmt = 1'b0;
	@(posedge rdy);
	if (rx_data !== tx_data) begin
		test_passed = 0;
		$display("Error at time %t: recieved data was %h but should be %h", $time, rx_data, tx_data);
	end
	
	// Make sure rdy is still asserted after some time
	@(posedge tx_done);
	repeat(50) @(posedge clk);
	if (rx_data !== tx_data) begin
		test_passed = 0;
		$display("Error at time %t: ready signal of UART_rx should still be asserted", $time);
	end
	
	// Clear rdy
	clr_rdy = 1;
	@(posedge clk);
	clr_rdy = 0;
	#1 if (rdy) begin
		test_passed = 0;
		$display("Error at time %t: ready signal of UART_rx not cleared", $time);
	end
	
	// Test transmitting all zeros
	tx_data = 8'h00;
	trmt = 1'b1;
	@(posedge clk);
	trmt = 1'b0;
	@(posedge rdy);
	if (rx_data !== tx_data) begin
		test_passed = 0;
		$display("Error at time %t: recieved data was %h but should be %h", $time, rx_data, tx_data);
	end
	
	// Test transmitting all ones
	@(posedge tx_done);
	tx_data = 8'hFF;
	trmt = 1'b1;
	@(posedge clk);
	trmt = 1'b0;
	@(posedge rdy);
	if (rx_data !== tx_data) begin
		test_passed = 0;
		$display("Error at time %t: recieved data was %h but should be %h", $time, rx_data, tx_data);
	end
	
	if (test_passed)
		$display("All tests passed");
	
	$stop();
end

always
	#2 clk = ~clk;

endmodule
`default_nettype wire