module cmd_proc_tb();

//inputs for RemoteComm
logic [15:0] cmd;
logic snd_cmd;
logic clk, rst_n;
//Outputs for RemoteComm
logic [7:0] resp;
logic resp_rdy;
logic cmd_sent;

//Intermediary from RC to Wrapper
logic RX, TX;
logic trmt;
logic tx_done;

//Intermediary from wrapper to cmd_proc
logic [15:0] cmdOut;
logic cmd_rdy, clr_cmd_rdy;
logic send_resp;
logic [7:0] respIn;

//Intermediary from NEMO to inert_intf
logic INT, MISO; //Out NEMO
logic SS_n, SCLK, MOSI; //In NEMO
logic rdy;

//Intermediary from inert_intf to cmd_proc
logic lftIR;
logic rghtIR;
logic [11:0] heading;
logic heading_rdy, cal_done;
logic moving, strt_cal;

//Inputs for cmd_proc

logic cntrIR;

//Outputs for cmd_proc
logic fanfare_go, tour_go;
logic [9:0] frwrd;
logic [11:0] error;


//Instantiate and Declare all neccesary blocks
RemoteComm remote(.clk, .rst_n, .RX, .TX, .cmd, .send_cmd(snd_cmd), .cmd_sent, .resp_rdy, .resp);

UART_wrapper wrapper(.clk, .rst_n, .RX(TX), .trmt, .clr_cmd_rdy, .resp(respIn), .tx_done, .TX(RX), 
.cmd_rdy, .cmd(cmdOut));

SPI_iNEMO3 nemo3(.SS_n,.SCLK,.MISO,.MOSI,.INT);

inert_intf inert(.clk,.rst_n,.strt_cal,.cal_done,.heading,.rdy(heading_rdy),.lftIR,
                  .rghtIR,.SS_n,.SCLK,.MOSI,.MISO,.INT,.moving);
				  
cmd_proc iDUT(.clk,.rst_n,.cmd(cmdOut),.cmd_rdy,.clr_cmd_rdy,.send_resp,.strt_cal,
                .cal_done,.heading,.heading_rdy,.lftIR,.cntrIR,.rghtIR,.error,
				.frwrd,.moving,.tour_go,.fanfare_go);

//Test Block- 
initial begin
//Establish all inputs to known values and asssert/deassert reset
//Need clk, rst_n, lftIR, rghtIR, resp, cmd, snd_cmd, cntrIR 
clk = 0;
rst_n = 0;
lftIR = 0;
rghtIR = 0;
resp = 8'hA5;
cmd = 16'h0000;
cntrIR = 0;

@(negedge clk);

rst_n = 1;
snd_cmd = 1;
@(posedge clk)
snd_cmd = 0;

//Send Calibrate command, waiting for cal_done and resp_rdy
fork
	begin : calibrate1
		repeat(1000000) @(posedge clk);
		$display("ERROR: cal_done never asserted");
		$stop();
	end
	begin
		@(posedge cal_done);
		disable calibrate1;
	end
join
	

fork
	begin : calibrate2
		repeat(1000000) @(posedge clk);
		$display("ERROR: resp_rdy never asserted");
		$stop();
	end
	begin
		@(posedge resp_rdy);
		disable calibrate2;
	end
join
	




//Send command to move north 1 square
cmd = 16'h2001;

@(posedge clk);
snd_cmd = 1;
@(posedge clk);
snd_cmd = 0;

//Ensuring that cmd was sent and speed is 0
fork
	begin : moveNorth1
		repeat(1000000) @(posedge clk);
		$display("ERROR: cmd_sent never asserted");
		$stop();
	end
	begin
		@(posedge cmd_sent);
		disable moveNorth1;
	end
join
	if(!frwrd == 10'h000) begin
		$display("ERROR: frwrd should be 10'h000");
		$stop();
	end
	
//Makes sure heading is incrementing as expected 
fork
	begin : headingCheck
		repeat(1000000) @(posedge clk);
		$display("ERROR: heading_rdy not asserted 10 times");
		$stop();
	end : headingCheck
	begin : Check
		repeat(10)@(posedge heading_rdy);
		disable headingCheck;
	end : Check
join
	if(frwrd != 10'h120 && frwrd != 10'h140) begin
		$display("ERROR: frwrd should be 10'h120 or 10'h140 %h", frwrd);
		$stop();
	end

//frwrd is non zero, moving should be set
if(!moving)begin
	$display("Moving should be asserted at this time");
	$stop();
end

//frwrd should be max speed by this point, many heading_rdy edges 
fork
	begin : maxSpeed
		repeat(1000000) @(posedge clk);
		$display("ERROR: heading_rdy not asserted 20+ times");
		$stop();
	end
	begin
		repeat(30)@(posedge heading_rdy);
		disable maxSpeed;
	end
join
	if(frwrd != 10'hF00) begin
		$display("ERROR: frwrd should be at max speed");
		$stop();
	end

//represents knight crossing a line
cntrIR = 1;
@(posedge clk);
cntrIR = 0;

repeat(100000) @(posedge clk);

if(frwrd != 10'hF00) begin
		$display("ERROR: frwrd should be at max speed");
		$stop();
end

//knight crosses a second line, should start slowing down
cntrIR = 1;
@(posedge clk);
cntrIR = 0;

//Checks that knight eventually stops moving 
fork
	begin : stopMove
		repeat(1000000) @(posedge clk);
		$display("ERROR: resp_rdy not asserted");
		$stop();
	end
	begin
		@(negedge resp_rdy);
		disable stopMove;
	end
join
	if(moving) begin
		$display("ERROR: Knight should not be moving");
		$stop();
	end

//send another move north 1 square

snd_cmd = 1;
@(posedge clk);
snd_cmd = 0;

//Waiting until the knight gets to max speed
fork
	begin : maxSpeed2
		repeat(100000000) @(posedge clk);
		$display("ERROR: Unable to reach max speed, heading rdy not asserting");
		$stop();
	end
	begin
		repeat(50)@(posedge heading_rdy);
		disable maxSpeed2;
	end
join
	if(frwrd != 10'hF00) begin
		$display("ERROR: frwrd should be at max speed");
		$stop();
	end

//Knight should be moving 
if(!moving) begin
	$display("Moving should be asserted at this time");
	$stop();
end

$display("original error: %h\n", error);

//This input should throw off error signifiacntly, compare printed values
rghtIR = 1;
repeat(1000000) @(posedge clk);
rghtIR = 0;

$display("New Error: %h\n", error);
$display("YAHOOO: TEST PASSED!!!!");
$stop();
end

always 
#5 clk = ~clk;

endmodule