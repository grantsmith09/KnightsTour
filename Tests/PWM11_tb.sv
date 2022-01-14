// File: PWM11_tb.sv
// Description: Tests the functionallity of the 11-bit PWM signal generator.
// Author: Trevor Wallis
`default_nettype none

module PWM11_tb();

reg clk, rst_n;
reg [10:0] duty;
logic PWM_sig, PWM_sig_n;

PWM11 iDUT(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM_sig(PWM_sig), .PWM_sig_n(PWM_sig_n));

initial begin
	clk = 0;
	rst_n = 1;
	duty = 11'h000;
	
	// Initialize 11 bit PWM module to a known state
	@(posedge clk);
	@(negedge clk);
	rst_n = 0;
	@(posedge clk);
	@(negedge clk);
	rst_n = 1;
	
	// PWM signal should be 0%
	repeat(4096)@(posedge clk);
	
	// PWM signal should be 50%
	duty = 11'h400;
	repeat(4096)@(posedge clk);
	
	//PWM signal should be 100%
	duty = 11'hFFF;
	repeat(4096)@(posedge clk);
	
	$stop();
end

always
	#5 clk = ~clk;

endmodule
`default_nettype wire