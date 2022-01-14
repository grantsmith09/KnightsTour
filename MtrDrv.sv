// File: MtrDrv.sv
// Description: Controls the PWM signal sent to the left and right motors of the robot based on the provided speed for each side.
// Author: Trevor Wallis
`default_nettype none

module MtrDrv(lft_spd, rght_spd, lftPWM1, lftPWM2, rghtPWM1, rghtPWM2, clk, rst_n);

input logic [10:0] lft_spd, rght_spd;
input logic  clk, rst_n;
output logic lftPWM1, lftPWM2, rghtPWM1, rghtPWM2;

logic [10:0] leftDuty, rightDuty;

  PWM11 PWMlft(.clk(clk), .rst_n(rst_n), .duty(leftDuty), .PWM_sig(lftPWM1), .PWM_sig_n(lftPWM2));
  PWM11 PWMrght(.clk(clk), .rst_n(rst_n), .duty(rightDuty), .PWM_sig(rghtPWM1), .PWM_sig_n(rghtPWM2));

assign leftDuty = lft_spd + 11'h400;
assign rightDuty = rght_spd + 11'h400;

endmodule
`default_nettype wire
