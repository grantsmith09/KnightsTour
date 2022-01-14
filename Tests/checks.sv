localparam BOARD_BOTTOM_LEFT = 15'h0800;

// Checks the knight after reset to ensure it is in the expected state
task automatic checkReset(ref clk, ref lftPWM1, ref lftPWM2, ref rghtPWM1, ref rghtPWM2, ref testPassed);
	reg lftPWMPassed, rghtPWMPassed;
	lftPWMPassed = 1;
	rghtPWMPassed = 1;
	checkPWMDuty(clk, lftPWM1, lftPWM2, 11'h400, lftPWMPassed);
	checkPWMDuty(clk, rghtPWM1, rghtPWM2, 11'h400, rghtPWMPassed);
	if (!lftPWMPassed) begin
		testPassed = 0;
		$display("Error: left PWM signal is not correct after reset");
	end
	if (!rghtPWMPassed) begin
		testPassed = 0;
		$display("Error: right PWM signal is not correct after reset");
	end
endtask

// Checks the knight after calibration to ensure it is in the expected state
task automatic checkCalibrate(ref clk, ref cmd_sent, ref testPassed);
	checkCommandRecieved(clk, cmd_sent, testPassed);
endtask

// Takes the expected position of the robot from 0-4 for x and y and the actual position of the robot
task automatic checkPosition(input [2:0] expectedX, input [2:0] expectedY, input [14:0] actualX, input [14:0] actualY, ref testPassed);
	if (actualX[14:12] !== expectedX) begin
		testPassed = 0;
		$display("Error: robot was expected to be a x=%d but was at x=%d", expectedX, actualX[14:12]);
	end
	if (actualY[14:12] !== expectedY) begin
		testPassed = 0;
		$display("Error: robot was expected to be at y=%d but was at y=%d", expectedY, actualY[14:12]);
	end
endtask

// Makes sure the knight acknowledges a command as recieved
task automatic checkCommandRecieved(ref clk, ref cmd_sent, ref testPassed);
	fork
		begin : cmdRecieved
			repeat(200000) @(posedge clk);
			testPassed = 0;
			$display("Error: command not marked as recieved by knight");
		end
		begin
			@(posedge cmd_sent);
			disable cmdRecieved;
		end
	join
endtask

// Makes sure there is activity on the piezo lines when a fanfare is played
task automatic checkPiezo(ref clk, ref piezo, ref piezo_n, ref testPassed);
	fork
		begin
			@(posedge piezo);
			if(piezo_n != 0) begin
				testPassed = 0;
				$display("Error: piezo_n unexpected value");
			end
			@(negedge piezo);
			if(piezo_n != 1) begin
				testPassed = 0;
				$display("Error: piezo_n unexpected value");
			end
			disable piezo_check;
		end
		begin : piezo_check
			repeat(10000000) @(posedge clk);
			testPassed = 0;
			$display("Error: piezo lines did not change");
		end
	join
endtask

// Monitors the tour and makes sure each square is only visited once
task automatic checkTour(ref [14:0] robotX, ref [14:0] robotY, ref [7:0] resp, ref resp_rdy, ref testPassed);
	reg [4:0][4:0] squares;
	int i, j;
	for (i = 0; i < 5; i = i + 1) begin
		for (j = 0; j < 5; j = j + 1) begin
			squares[i][j] = 0;
		end
	end
	
	// Starting location of the knight
	squares[robotX[14:12]][robotY[14:12]] = 1;
	
	// Intermediary moves of the tour
	repeat(23) begin
		repeat(2) @(posedge resp_rdy);
		// Uncomment below line to assist with debugging
		//$display("At position x: %d  y: %d", robotX[14:12], robotY[14:12]);
		if (squares[robotX[14:12]][robotY[14:12]] === 1) begin
			testPassed = 0;
			$display("Error: Square visited more than once");
		end
		else begin
			squares[robotX[14:12]][robotY[14:12]] = 1;
			checkResponse(1, resp, testPassed);
		end
	end
	
	// Final move of the tour
	repeat(2) @(posedge resp_rdy);
	if (squares[robotX[14:12]][robotY[14:12]] === 1) begin
		testPassed = 0;
		$display("Error: Square visited more than once");
	end
	checkResponse(0, resp, testPassed);
endtask

// Checks the response from the UART passed into RemoteComm to make sure it is as expected
// An input of 1 means an intermediary move occured
task automatic checkResponse(input intermediaryMove, input [7:0] resp, ref testPassed);
	logic [7:0] expectedResp;
	if (intermediaryMove)
		expectedResp = 8'h5a;
	else
		expectedResp = 8'ha5;
		
	if (resp !== expectedResp) begin
		testPassed = 0;
		$display("Error: response from knight was %h when %h was expected", resp, expectedResp);
	end
endtask

// Checks that PWM is at the desired duty cycle
// Changes testCompleteSignal when the test is done
task automatic checkPWMDuty(ref clk, ref PWM1, ref PWM2, input [10:0] duty, ref testPassed);
	localparam PWM_ERROR = 11'h005; // Allowed error due to unexpected course correction
	reg [10:0] actualDuty;
	actualDuty = 11'h000;
	repeat(2048) @(posedge clk) begin : PWMTest
		if (PWM1 === PWM2) begin
			testPassed = 0;
			$display("Error: PWM signals are not opposites of each other");
			disable PWMTest;
		end
		if (PWM1 === 1'b1)
			actualDuty = actualDuty + 1;
	end
	if (actualDuty >= duty + PWM_ERROR || actualDuty <= duty - PWM_ERROR) begin
		testPassed = 0;
		$display("Error: actual duty (%h) does not match intended duty (%h)", actualDuty, duty);
	end
endtask