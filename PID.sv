// File: PID.sv
// Author: Trevor Wallis
`default_nettype none

module PID(clk, rst_n, moving, err_vld, error, frwrd, lft_spd, rght_spd);

input logic clk, rst_n, err_vld, moving;
input logic signed [11:0] error;
input logic [9:0] frwrd;
output logic [10:0] lft_spd, rght_spd;

localparam signed D_COEFF = 6'h0B;
localparam signed P_COEFF = 5'h8;

// P term
	logic signed [13:0] P_term;
	logic signed [9:0] err_sat;

	assign err_sat = (~error[11] & |error[10:9]) ? 10'h1FF : 
					(error[11] & ~&error[10:9]) ? 10'h200 :
					error[9:0];

	assign 	P_term = err_sat * P_COEFF;

// I term
	logic signed [13:0] I_term;
	logic [14:0] err_sat_extend, integrator;
	logic [14:0] integrator_sum, nxt_integrator, nxt_integrator_if_moving;
	logic overflow;					// Has a value of 1 if the sum has overflowed
	logic select_integrator_sum;

	// Sign extend err_sat
	assign err_sat_extend = {{5{err_sat[9]}}, err_sat[9:0]};

	// Generate the sum of the current integrator and err_sat and select the next value for the integrator
	assign integrator_sum = integrator + err_sat_extend;
	assign nxt_integrator_if_moving = (select_integrator_sum) ? integrator_sum : integrator;
	assign nxt_integrator = (moving) ? nxt_integrator_if_moving : 15'h0000;

	// Determine if the integrator is saturated
	assign overflow =	(err_sat_extend[14] == integrator[14] && integrator[14] == !integrator_sum[14]) ? 1'b1 : 1'b0;
						
	assign select_integrator_sum = (~overflow & err_vld) ? 1'b1 : 1'b0;

	// Flip flop with synchronous reset
	always_ff@(posedge clk, negedge rst_n) begin
		if (!rst_n)
			integrator <= 15'h0000;
		else
			integrator <= nxt_integrator;
	end

	// Generate I_term
	assign I_term = {{6{integrator[14]}}, integrator[14:6]};

// D term
	logic signed [13:0] D_term_se;
	logic signed [12:0] D_term;
	reg signed [9:0] ff1_out, ff2_out;
	logic signed [9:0] D_diff;
	logic signed [6:0] D_diff_sat;

	// Two flip-flops in series
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			ff1_out <= 10'b000;
			ff2_out <= 10'b000;
		end
		else if (err_vld) begin
			ff1_out <= err_sat;
			ff2_out <= ff1_out;
		end
	end

	assign D_diff = err_sat - ff2_out;
	assign D_diff_sat = (~D_diff[9] & |D_diff[8:6]) ? 7'h3F : 
					(D_diff[9] & ~&D_diff[8:6]) ? 7'h40 :
					D_diff[6:0];
	assign D_term = D_diff_sat * D_COEFF;
	assign D_term_se = {D_term[12], D_term};

// Creation of PID accounting for overflow
	logic [13:0] PID;
	assign PID = P_term + I_term + D_term_se;

// Zero extend frwrd for lft_spd and rght_spd
	logic [10:0] frwrd_ze;
	assign frwrd_ze = {1'b0, frwrd};

// Create lft_spd
	logic [10:0] lft_unsat, lft_sat;
	assign lft_unsat = frwrd_ze + PID[13:3];
	assign lft_sat = (~PID[13] && lft_unsat[10]) ? 11'h3ff : lft_unsat;
	assign lft_spd = moving ? lft_sat : 11'h000;

// Create rght_spd
	logic [10:0] rght_unsat, rght_sat;
	assign rght_unsat = frwrd_ze - PID[13:3];
	assign rght_sat = (PID[13] && rght_unsat[10]) ? 11'h3ff : rght_unsat;
	assign rght_spd = moving ? rght_sat : 11'h000;

endmodule
`default_nettype wire