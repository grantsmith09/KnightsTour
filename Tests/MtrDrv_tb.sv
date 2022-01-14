// File: MtrDrv_tb.sv
// Description: Tests the functionallity of the motor controller.
// Author: Trevor Wallis
`default_nettype none

module MtrDrv_tb();

reg clk, rst_n;
reg [10:0] lft_spd, rght_spd;
logic lftPWM1, lftPWM2, rghtPWM1, rghtPWM2;

MtrDrv iDUT(.lft_spd(lft_spd), .rght_spd(rght_spd), .lftPWM1(lftPWM1), .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2), .clk(clk), .rst_n(rst_n));

initial begin
	clk = 0;
	
	// Initialize MtrDrv to a known state
	@(posedge clk);
	@(negedge clk);
	rst_n = 0;
	@(posedge clk);
	@(negedge clk);
	rst_n = 1;
	
	// Test sending a positive speed to both motors with a 100% duty cycle
	lft_spd = 11'h3FF;
	rght_spd = 11'h3FF;
	repeat(4096)@(posedge clk);
	
	
	// Test sending a negative speed to both motors with a 0% duty cycle
	lft_spd = 11'h400;
	rght_spd = 11'h400;
	repeat(4096)@(posedge clk);
	
	// Test sending different speeds to both motors
	rght_spd = 11'h3FF;
	repeat(4096)@(posedge clk);
	
	$stop();
end

always
	#5 clk = ~clk;

endmodule
`default_nettype wire