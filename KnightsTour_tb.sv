module KnightsTour_tb();

	`include "initialization.sv"
	`include "sendcommand.sv"
	`include "checks.sv"
	
	// Enable controls for tests
	localparam TEST_MOVES = 1;
	localparam TEST_TOURS = 1;
	localparam TEST_POST_SYNTH = 0; // Removes dependancy of tests on iDUT internal signals when having a value of 1
	
	/////////////////////////////
	// Stimulus of type reg //
	/////////////////////////
	reg clk, RST_n;
	reg [15:0] cmd;
	reg send_cmd;

	///////////////////////////////////
	// Declare any internal signals //
	/////////////////////////////////
	logic SS_n,SCLK,MOSI,MISO,INT;
	logic lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
	logic TX_RX, RX_TX;
	logic cmd_sent;
	logic resp_rdy;
	logic [7:0] resp;
	logic IR_en;
	logic lftIR_n,rghtIR_n,cntrIR_n;
	logic piezo, piezo_n;

	//////////////////////
	// Instantiate DUT //
	////////////////////
	KnightsTour iDUT(.clk(clk), .RST_n(RST_n), .SS_n(SS_n), .SCLK(SCLK),
						   .MOSI(MOSI), .MISO(MISO), .INT(INT), .lftPWM1(lftPWM1),
						   .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
						   .RX(TX_RX), .TX(RX_TX), .piezo(piezo), .piezo_n(piezo_n),
						   .IR_en(IR_en), .lftIR_n(lftIR_n), .rghtIR_n(rghtIR_n),
						   .cntrIR_n(cntrIR_n));
			  
	/////////////////////////////////////////////////////
	// Instantiate RemoteComm to send commands to DUT //
	///////////////////////////////////////////////////
	RemoteComm iRMT(.clk(clk), .rst_n(RST_n), .RX(RX_TX), .TX(TX_RX), .cmd(cmd),
					.send_cmd(send_cmd), .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(resp));

	//////////////////////////////////////////////////////
	// Instantiate model of Knight Physics (and board) //
	////////////////////////////////////////////////////
	KnightPhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                      .MOSI(MOSI),.INT(INT),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
					  .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),.IR_en(IR_en),
					  .lftIR_n(lftIR_n),.rghtIR_n(rghtIR_n),.cntrIR_n(cntrIR_n)); 
	
	reg testPassed;
	initial begin
		initializeSignals(testPassed, clk, RST_n, cmd, send_cmd);
		
		// Make sure the knight properly resets
		reset(clk, RST_n);
		fork
			begin : reset1
				repeat(100000) @(posedge clk);
				$display("Critical error: NEMO_setup never asserted");
				$stop();
			end
			begin
				@(posedge iPHYS.iNEMO.NEMO_setup);
				disable reset1;
			end
		join
		checkReset(clk, lftPWM1, lftPWM2, rghtPWM1, rghtPWM2, testPassed);
		
		// Calibrate the knight
		calibrate(clk, send_cmd, cmd);
		fork
			begin : calibrate1
				repeat(500000) @(posedge clk);
				$display("Critical error: cal_done is never asserted");
				$stop();
			end
			begin
				checkCalibrate(clk, cmd_sent, testPassed);
			end
			begin
				if (TEST_POST_SYNTH)
					repeat(450000) @(posedge clk);
				else
					@(posedge iDUT.cal_done);
				disable calibrate1;
			end
		join
		
		if (TEST_MOVES) begin
			$display("At move testing stage");
			
			// Move north one square
			fork
				begin : move1
					repeat(10000000) @(posedge clk);
					$display("Critical error: First move never completed");
					$stop();
				end
				begin
					// Test max PWM on left drive
					if (TEST_POST_SYNTH)
						repeat(600000) @(posedge clk);
					else
						@(posedge iDUT.iCMD.max_speed);
					checkPWMDuty(clk, lftPWM1, lftPWM2, 11'h700, testPassed);
				end
				begin
					// Test max PWM on right drive
					if (TEST_POST_SYNTH)
						repeat(600000) @(posedge clk);
					else
						@(posedge iDUT.iCMD.max_speed);
					checkPWMDuty(clk, rghtPWM1, rghtPWM2, 11'h700, testPassed);
				end
				begin
					move(NORTH, 3'b001, clk, cmd, send_cmd);
					checkCommandRecieved(clk, cmd_sent, testPassed);
					@(posedge resp_rdy);
					disable move1;
				end
			join
			checkPosition(3'b010, 3'b011, iPHYS.xx, iPHYS.yy, testPassed);
			
			// Move south two squares
			fork
				begin : move2
					repeat(10000000) @(posedge clk);
					$display("Critical error: Second move never completed");
					$stop();
				end
				begin
					move(SOUTH, 3'b010, clk, cmd, send_cmd);
					checkCommandRecieved(clk, cmd_sent, testPassed);
					@(posedge resp_rdy);
					disable move2;
				end
			join
			checkPosition(3'b010, 3'b001, iPHYS.xx, iPHYS.yy, testPassed);
			
			// Move east two squares
			fork
				begin : move3
					repeat(10000000) @(posedge clk);
					$display("Critical error: Third move never completed");
					$stop();
				end
				begin
					move(EAST, 3'b010, clk, cmd, send_cmd);
					checkCommandRecieved(clk, cmd_sent, testPassed);
					@(posedge resp_rdy);
					disable move3;
				end
			join
			checkPosition(3'b100, 3'b001, iPHYS.xx, iPHYS.yy, testPassed);
			
			// Move west one square
			fork
				begin : move4
					repeat(10000000) @(posedge clk);
					$display("Critical error: Fourth move never completed");
					$stop();
				end
				begin
					move(WEST, 3'b001, clk, cmd, send_cmd);
					checkCommandRecieved(clk, cmd_sent, testPassed);
					@(posedge resp_rdy);
					disable move4;
				end
			join
			checkPosition(3'b011, 3'b001, iPHYS.xx, iPHYS.yy, testPassed);
			
			// Test move west one square with fanfare
			fork
				begin : moveFanfare1
					repeat(10000000) @(posedge clk);
					$display("Critical error: First move with fanfare never completed");
					$stop();
				end
				begin
					checkPiezo(clk, piezo, piezo_n, testPassed);
				end
				begin
					moveFanfare(WEST, 3'b001, clk, cmd, send_cmd);
					checkCommandRecieved(clk, cmd_sent, testPassed);
					@(posedge resp_rdy);
					disable moveFanfare1;
				end
			join
			checkPosition(3'b010, 3'b001, iPHYS.xx, iPHYS.yy, testPassed);
		end
		
		if (TEST_TOURS) begin
			$display("At tour testing stage");
			
			// Test running a tour from the center
			resetRobot(clk, RST_n, iPHYS.omega_lft, iPHYS.omega_rght, iPHYS.heading_robot, iPHYS.xx, iPHYS.yy, iPHYS.lftIR_n, iPHYS.cntrIR_n, iPHYS.rghtIR_n, cmd, send_cmd);
			if (TEST_POST_SYNTH)
				repeat(450000) @(posedge clk);
			else
				@(posedge iDUT.cal_done);
			tourCenter(clk, cmd, send_cmd);
			fork
				begin : tour1
					repeat(1000000000) @(posedge clk);
					$display("Critical error: First tour never completed");
					$stop();
				end
				begin
					checkTour(iPHYS.xx, iPHYS.yy, resp, resp_rdy, testPassed);
					disable tour1;
				end
				begin
					checkCommandRecieved(clk, cmd_sent, testPassed);
				end
			join
		end

	if (testPassed == 1)
		$display("All tests passed");
	$stop();
	end
  
	always
		#5 clk = ~clk;
  
endmodule
