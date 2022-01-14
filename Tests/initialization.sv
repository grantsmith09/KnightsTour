// Sets up the test bench signals
task automatic initializeSignals(ref testPassed, ref clk, ref RST_n, ref [15:0] cmd, ref send_cmd);
	testPassed = 1;
	clk = 0;
	RST_n = 1;
	cmd = 16'h0000;
	send_cmd = 0;
endtask

// Triggers the reset signal
task automatic reset(ref clk, ref RST_n);
	@(negedge clk);
	RST_n = 0;
	@(posedge clk);
	RST_n =1;
endtask

// Triggers the reset signal and sets the physics model back to the center of the board
task automatic resetRobot(ref clk, ref RST_n, ref signed [15:0] omega_lft, ref signed [15:0] omega_rght, ref signed [19:0] heading_robot, ref logic [14:0] xx, ref logic [14:0] yy, ref lftIR_n, ref cntrIR_n, ref rghtIR_n, ref [15:0] cmd, ref send_cmd);
	@(negedge clk);
	RST_n = 0;
	@(posedge clk);
	RST_n =1;
	// Resets the physics model to the center of the board
	omega_lft = 16'h0000;
	omega_rght = 16'h0000;
	heading_robot = 20'h00000;
	xx = 15'h2800;
	yy = 15'h2800;
	lftIR_n = 1;
	cntrIR_n = 1;
	rghtIR_n = 1;
	@(posedge clk);
	calibrate(clk, send_cmd, cmd);
endtask