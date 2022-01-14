// File: TourCmd_tb.sv
// Description: Tests the implementation of TourCmd
// Author: Trevor Wallis
`default_nettype none

module TourCmd_tb();

reg clk, test_passed, rst_n, start_tour, cmd_rdy_UART, clr_cmd_rdy, send_resp;
reg [7:0] move;
reg [15:0] cmd_UART, cmd_expected;
logic [4:0] mv_indx;
logic [15:0] cmd;
logic [7:0] resp;
logic cmd_rdy;

TourCmd iDUT(.clk, .rst_n, .start_tour, .mv_indx, .move, .cmd_UART, .cmd_rdy_UART, .cmd, .cmd_rdy, .clr_cmd_rdy, .send_resp, .resp);

initial begin
	clk = 0;
	clr_cmd_rdy = 0;
	test_passed = 1;
	rst_n = 0;
	move = 8'b00000001;
	cmd_UART = 16'h3fae;
	start_tour = 0;
	cmd_rdy_UART = 0;
	send_resp = 0;
	
	@(negedge clk);
	rst_n = 1;
	
	// Make sure UART command is passed through initially
	@(posedge clk);
	if (cmd !== cmd_UART || cmd_rdy !== cmd_rdy_UART) begin
		test_passed = 0;
		$display("Error: UART command not passed through after reset");
	end
	
	// Test a +2 Y, -1 X move
	start_tour = 1;
	@(posedge clk);
	start_tour = 0;
	fork
		begin : move1
			repeat(10000) @(posedge clk);
			$display("Error: cmd_rdy never asserted");
			$stop();
		end
		begin
			@(posedge cmd_rdy);
			disable move1;
		end
	join
		// Horizontal move
	clr_cmd_rdy = 1;
	@(posedge clk);
	clr_cmd_rdy = 0;
	cmd_expected = 16'h23f1;
	if (cmd !== cmd_expected) begin
		test_passed = 0;
		$display("Error: cmd provided was %h but should be %h", cmd, cmd_expected);
	end
	if (mv_indx !== 5'b00000) begin
		test_passed = 0;
		$display("Error: move index was %h but should be %h", mv_indx, 5'b00000);
	end
		// Vertical move
	send_resp = 1;
	@(posedge clk);
	send_resp = 0;
	@(posedge cmd_rdy);
	clr_cmd_rdy = 1;
	@(posedge clk);
	clr_cmd_rdy = 0;
	cmd_expected = 16'h3002;
	if (cmd !== cmd_expected) begin
		test_passed = 0;
		$display("Error: cmd provided was %h but should be %h", cmd, cmd_expected);
	end
	if (mv_indx !== 5'b00000) begin
		test_passed = 0;
		$display("Error: move index was %h but should be %h", mv_indx, 5'b00000);
	end
	
	// Test a +2 Y, +1 X move
	move = 8'b00000010;
		// Horizontal move
	send_resp = 1;
	@(posedge clk);
	send_resp = 0;
	if (resp !== 8'h5a) begin
		test_passed = 0;
		$display("Error: resp should be 5a on intermediate moves");
	end
	@(posedge cmd_rdy);
	clr_cmd_rdy = 1;
	@(posedge clk);
	clr_cmd_rdy = 0;
	if (mv_indx !== 5'b00001) begin
		test_passed = 0;
		$display("Error: move index was %h but should be %h", mv_indx, 5'b00001);
	end
	cmd_expected = 16'h2bf1;
	if (cmd !== cmd_expected) begin
		test_passed = 0;
		$display("Error: cmd provided was %h but should be %h", cmd, cmd_expected);
	end
		// Vertical move
	send_resp = 1;
	@(posedge clk);
	send_resp = 0;
	if (resp !== 8'h5a) begin
		test_passed = 0;
		$display("Error: resp should be 5a on intermediate moves");
	end
	@(posedge cmd_rdy);
	clr_cmd_rdy = 1;
	@(posedge clk);
	clr_cmd_rdy = 0;
	cmd_expected = 16'h3002;
	if (cmd !== cmd_expected) begin
		test_passed = 0;
		$display("Error: cmd provided was %h but should be %h", cmd, cmd_expected);
	end
	if (mv_indx !== 5'b00001) begin
		test_passed = 0;
		$display("Error: move index was %h but should be %h", mv_indx, 5'b00001);
	end
	
	// Test a -2 Y, -1 X
	move = 8'b00010000;
		// Horizontal move
	send_resp = 1;
	@(posedge clk);
	send_resp = 0;
	if (resp !== 8'h5a) begin
		test_passed = 0;
		$display("Error: resp should be 5a on intermediate moves");
	end
	@(posedge cmd_rdy);
	clr_cmd_rdy = 1;
	@(posedge clk);
	clr_cmd_rdy = 0;
	if (mv_indx !== 5'b00010) begin
		test_passed = 0;
		$display("Error: move index was %h but should be %h", mv_indx, 5'b00010);
	end
	cmd_expected = 16'h23f1;
	if (cmd !== cmd_expected) begin
		test_passed = 0;
		$display("Error: cmd provided was %h but should be %h", cmd, cmd_expected);
	end
		// Vertical move
	send_resp = 1;
	@(posedge clk);
	send_resp = 0;
	if (resp !== 8'h5a) begin
		test_passed = 0;
		$display("Error: resp should be 5a on intermediate moves");
	end
	@(posedge cmd_rdy);
	clr_cmd_rdy = 1;
	@(posedge clk);
	clr_cmd_rdy = 0;
	cmd_expected = 16'h37f2;
	if (cmd !== cmd_expected) begin
		test_passed = 0;
		$display("Error: cmd provided was %h but should be %h", cmd, cmd_expected);
	end
	if (mv_indx !== 5'b00010) begin
		test_passed = 0;
		$display("Error: move index was %h but should be %h", mv_indx, 5'b00010);
	end
	
	// Test return of UART control
	repeat(21) begin
			// Horizontal move
		send_resp = 1;
		@(posedge clk);
		send_resp = 0;
		if (resp !== 8'h5a) begin
			test_passed = 0;
			$display("Error: resp should be 5a on intermediate moves");
		end
		@(posedge cmd_rdy);
		clr_cmd_rdy = 1;
		@(posedge clk);
		clr_cmd_rdy = 0;
		cmd_expected = 16'h23f1;
		if (cmd !== cmd_expected) begin
			test_passed = 0;
			$display("Error: cmd provided was %h but should be %h", cmd, cmd_expected);
		end
			// Vertical move
		send_resp = 1;
		@(posedge clk);
		send_resp = 0;
		if (resp !== 8'h5a) begin
			test_passed = 0;
			$display("Error: resp should be 5a on intermediate moves");
		end
		@(posedge cmd_rdy);
		clr_cmd_rdy = 1;
		@(posedge clk);
		clr_cmd_rdy = 0;
		cmd_expected = 16'h37f2;
		if (cmd !== cmd_expected) begin
			test_passed = 0;
			$display("Error: cmd provided was %h but should be %h", cmd, cmd_expected);
		end
	end
	send_resp = 1;
	@(posedge clk);
	send_resp = 0;
	if (resp !== 8'h5a) begin
		test_passed = 0;
		$display("Error: resp should be 5a on intermediate moves");
	end
	@(posedge clk);
	if (resp !== 8'ha5) begin
		test_passed = 0;
		$display("Error: resp should be a5 on the final move");
	end
	if (cmd !== cmd_UART || cmd_rdy !== cmd_rdy_UART) begin
		test_passed = 0;
		$display("Error: UART command not passed through after reset");
	end
	
	// Report on success
	if (test_passed)
		$display("All tests passed");
	
	$stop();
end

always
	#5 clk = ~clk;

endmodule
`default_nettype wire