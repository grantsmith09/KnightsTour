module PID_tb();

logic [24:0] stim [1999:0]; //Simulation Test values
logic [24:0] resp [1999:0];// Simulation Result Values
logic rst_n, moving, err_vld;//Reset, Moving, Error Valid
logic [11:0] error;//Error
logic [9:0] frwrd;//Forward
logic [10:0] lft_spd;//Left Speed
logic [10:0] rght_spd;//Right Speed
logic [10:0] lft_spd_result;//Left Speed Result
logic [10:0] rght_spd_result;//Right Speed Result
logic clk; //Clock
logic [11:0] i;//interator

//Instantiate DUT
PID iDut(.clk, .rst_n, .moving, .err_vld, .error, .frwrd, .lft_spd, .rght_spd);


initial begin
	//Read Hex Files
	$readmemh("PID_stim.hex", stim);
	$readmemh("PID_resp.hex", resp);
	clk = 0;
	
	
//Loop Through all results
for (i=0; i < 2000; i++)
	begin
	assign rst_n = stim[i][24];
	assign moving = stim[i][23];
	assign err_vld = stim[i][22];
	assign error = stim[i][21:10];
	assign frwrd =  stim[i][9:0];
	assign lft_spd_result = resp[i][21:11];
	assign rght_spd_result = resp[i][10:0];
	
	@(posedge clk);
	#1;
	
//Check for error	
	if(lft_spd !== lft_spd_result || rght_spd !== rght_spd_result) begin
		$display("Error lft spd should be %h is %h\n", lft_spd_result, lft_spd);
		$display("Error rght spd should be %h is %h\n", rght_spd_result, rght_spd);
		$stop;
	end
	
end

$display("Yahoo! All Test Passed, Victoria Schrimpf\n");
$stop;

end
	
always
	clk = #1 ~clk;


endmodule