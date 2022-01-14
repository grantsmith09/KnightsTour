// File: inert_intf_tb.sv
// Description: Tests the implementation of inert_inf
// Author: Trevor Wallis and Tori Schrimpf
`default_nettype none

module inert_intf_tb();

reg clk, test_passed, rst_n, strt_cal, lftIR, rghtIR, moving;
logic SS_n, cal_done, rdy, INT, SCLK, MOSI, MISO;
logic [11:0] heading;

inert_intf iDUT(.clk(clk),.rst_n(rst_n),.strt_cal(strt_cal),.cal_done(cal_done),.heading(heading),.rdy(rdy),.lftIR(lftIR),.rghtIR(rghtIR),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),.INT(INT),.moving(moving));
SPI_iNEMO2 iNEMO(.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),.INT(INT));

initial begin
	// Initialize inert_inf
	clk = 0;
	test_passed = 1;
	rst_n  = 0;
	strt_cal = 0;
	lftIR = 0;
	rghtIR = 0;
	moving = 1;
	@(posedge clk);
	@(negedge clk);
	rst_n = 1;
	@(posedge clk);
	
	// Wait for NEMO_setup
	@(posedge iNEMO.NEMO_setup);
	
	strt_cal = 1;
	@(posedge clk);
	strt_cal = 0;
	
	@(posedge cal_done);
	repeat(8000000) @(posedge clk);
	
	if (test_passed)
		$display("All tests passed");
	
	$stop();
end

always
	#5 clk = ~clk;

endmodule
`default_nettype wire