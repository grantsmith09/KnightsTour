module PID(clk, rst_n, moving, err_vld, error, frwrd, lft_spd, rght_spd);

input clk, rst_n, moving, err_vld; //clock, reset, moving, error valid
input signed [11:0] error; // signed input error
input [9:0] frwrd; //foward summed with PID
output [10:0] lft_spd; //left speed 
output [10:0] rght_spd; // right speed


//PTERM//

logic signed [13:0] P_term;
localparam signed P_COEFF = 5'h8;
logic signed  [9:0] err_sat;

//Check for Positive and Negative Saturation
assign err_sat = (!error[11] && |error[10:9]) ? 10'h1FF:
				 (error[11]  && ~&error[10:9]) ? 10'h200:
				 error[9:0];

assign P_term = err_sat * P_COEFF;


//ITERM//

logic [14:0] I_sum;
logic [14:0] nxt_integrator;
logic [14:0] integrator;
logic ov;
logic signed [9:0]outadder;
logic signed [6:0]sat;
logic signed [8:0] I_term;

assign I_sum = {{5{err_sat[9]}}, err_sat} + integrator;


//Overflow Check
assign ov = (err_sat[9] == integrator[14]) && (I_sum[14] != integrator[14]) ? 1 : 0;

assign nxt_integrator = !moving ? 15'h0000: ((!ov && err_vld) ? I_sum : integrator);

always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		integrator <= '0;
	else
		integrator <= nxt_integrator;
end

assign I_term = integrator[14:6];

///DTERM//
localparam signed D_COEFF = 6'h0B;
logic signed [9:0] firstdelay;
logic signed [9:0] seconddelay;
logic signed  [12:0] D_term;

//Firstdelay and Second Delay mux/flop
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		firstdelay <= integrator;
		seconddelay <= 15'h0000;
	end
	else if(err_vld) begin
		firstdelay <= err_sat;
		seconddelay <= firstdelay;
	end
	else begin
		firstdelay <= firstdelay;
		seconddelay <= seconddelay;
	end
end

//Subtraction
//adder
assign outadder = err_sat - seconddelay;

//saturate bits
assign sat = (!outadder[9] && |outadder[8:6]) ? 7'h3F:
			  (outadder[9] && ~&outadder[8:6]) ? 7'h40:
			   outadder[6:0];

//signed mulitply 			   
assign D_term = sat * D_COEFF; 
	

//PID added path
logic [13:0] PID;

assign PID ={{5{I_term[8]}}, I_term} + {D_term[12], D_term} + P_term; //: PID_sum;

//Zero Extend frwrd
logic [10:0] ZE_frwrd;

assign ZE_frwrd = {1'b0, frwrd};


//lft spd logic

//Intermediate values
logic [10:0] sum_frwrd_PID;

assign sum_frwrd_PID = PID[13:3] + ZE_frwrd;

//Saturation and assignment

assign lft_spd = moving ?  sum_frwrd_PID[10] && !PID[13] ? 11'h3ff: sum_frwrd_PID : 11'h000;



//rght spd logic
logic [10:0] sub_frwrd_PID;
logic ov_rght;

assign sub_frwrd_PID = ZE_frwrd - PID[13:3];

//Saturation and assignment

assign rght_spd = moving ? PID[13] && sub_frwrd_PID[10] ? 11'h3ff : sub_frwrd_PID : 11'h000;


endmodule