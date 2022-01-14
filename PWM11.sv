// File: PWM11.sv
// Description: Generates a PWM signal based on the applied 11-bit duty value. A higher duty results in a higer PWM duty cycle.
// Author: Trevor Wallis
`default_nettype none

module PWM11(clk, rst_n, duty, PWM_sig, PWM_sig_n);

input logic clk, rst_n;
input logic [10:0] duty;
output reg PWM_sig;
output logic PWM_sig_n;

reg [10:0] cnt;
logic cnt_less_duty;	// Carries a one if cnt is less than duty

// Flops the output to ensure a glitch free signal
always_ff@(posedge clk, negedge rst_n)
	if (!rst_n)
		PWM_sig <= 1'b0;
	else
		PWM_sig <= cnt_less_duty;

// Implements an 11-bit flip flop with synchronous reset that increses its count by 1 every clock cycle
always_ff@(posedge clk, negedge rst_n)
	if (!rst_n)
		cnt <= 11'h000;
	else
		cnt <= cnt + 11'h001;

assign cnt_less_duty = (cnt < duty) ? 1'b1 : 1'b0;

assign PWM_sig_n = ~PWM_sig;

endmodule
`default_nettype wire