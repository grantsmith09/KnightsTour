// File: inert_intf.sv
// Author: Trevor Wallis and Tori Schrimpf
`default_nettype none

module inert_intf(clk,rst_n,strt_cal,cal_done,heading,rdy,lftIR,rghtIR,SS_n,SCLK,MOSI,MISO,INT,moving);

  parameter FAST_SIM = 1;	// used to speed up simulation
  
  input logic clk, rst_n;
  input logic MISO;					// SPI input from inertial sensor
  input logic INT;					// goes high when measurement ready
  input logic strt_cal;				// initiate claibration of yaw readings
  input logic moving;					// Only integrate yaw when going
  input logic lftIR,rghtIR;			// gaurdrail sensors
  
  output logic cal_done;				// pulses high for 1 clock when calibration done
  output logic signed [11:0] heading;	// heading of robot.  000 = Orig dir 3FF = 90 CCW 7FF = 180 CCW
  output logic rdy;					// goes high for 1 clock when new outputs ready (from inertial_integrator)
  output logic SS_n,SCLK,MOSI;		// SPI outputs

  ////////////////////////////////////////////
  // Declare any needed internal registers //
  //////////////////////////////////////////
   reg INT1, INT_stable;
   reg [7:0] hold_yaw_high, hold_yaw_low;
   reg [15:0] timer;
  
  //////////////////////////////////////
  // Outputs of SM are of type logic //
  ////////////////////////////////////
   logic [15:0] cmd;
   logic store_yaw_high, store_yaw_low, vld, wrt, done;

  //////////////////////////////////////////////////////////////
  // Declare any needed internal signals that connect blocks //
  ////////////////////////////////////////////////////////////
  wire signed [15:0] ptch_rt,roll_rt,yaw_rt;	// feeds inertial_integrator
  wire signed [15:0] ax,ay;						// accel data to inertial_integrator
  wire [15:0] inert_data;
  
  
  ///////////////////////////////////////
  // Create enumerated type for state //
  /////////////////////////////////////
  typedef enum reg [2:0] {INIT1, INIT2, INIT3, WAIT, YAWL, YAWH, VALID} SM_state;
  SM_state state, next_state;
  
  // Gyro Commands
  localparam ENABLE_INT = 16'h0d02;
  localparam GYRO_SET = 16'h1160;
  localparam ROUND = 16'h1440;
  localparam YAW_L = 16'ha6xx;
  localparam YAW_H = 16'ha7xx;
  
  ////////////////////////////////////////////////////////////
  // Instantiate SPI monarch for Inertial Sensor interface //
  //////////////////////////////////////////////////////////
  SPI_mnrch iSPI(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),
                 .MISO(MISO),.MOSI(MOSI),.wrt(wrt),.done(done),
				 .rd_data(inert_data),.wt_data(cmd));
				  
  ////////////////////////////////////////////////////////////////////
  // Instantiate Angle Engine that takes in angular rate readings  //
  // and acceleration info and produces ptch,roll, & yaw readings //
  /////////////////////////////////////////////////////////////////
  inertial_integrator #(FAST_SIM) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal),.vld(vld),
                           .rdy(rdy),.cal_done(cal_done), .yaw_rt(yaw_rt),.moving(moving),.lftIR(lftIR),
                           .rghtIR(rghtIR),.heading(heading));
// Timer
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		timer <= 10'h000;
	else
		timer <= timer +1;
	
// Double flop of INT
always_ff @(posedge clk) begin
	INT1 <= INT;
	INT_stable <= INT1;
end

// Holding registers
always_ff @(posedge clk) begin
	if (store_yaw_high)
		hold_yaw_high <= inert_data;
	else if (store_yaw_low)
		hold_yaw_low <= inert_data;
end
assign yaw_rt = {hold_yaw_high, hold_yaw_low};

// State machine
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		state <= INIT1;
	else
		state <= next_state;

always_comb begin
	// Default state machine outputs
	next_state = state;
	store_yaw_high = 1'b0;
	store_yaw_low = 1'b0;
	wrt = 1'b0;
	vld = 1'b0;
	cmd = 16'hxxxx;
	case (state)
		INIT2: begin
			cmd = GYRO_SET;
			if (done) begin
				wrt = 1'b1;
				next_state = INIT3;
			end
		end
		INIT3: begin
			cmd = ROUND;
			if (done) begin
				wrt = 1'b1;
				next_state = WAIT;
			end
		end
		WAIT: begin
			cmd = YAW_L;
			if (INT_stable) begin
				wrt = 1'b1;
				next_state = YAWL;
			end
		end
		YAWL : begin
			cmd = YAW_H;
			if (done) begin
				wrt = 1'b1;
				store_yaw_low = 1'b1;
				next_state = YAWH;
			end
		end
		YAWH: begin
			if (done) begin
				store_yaw_high = 1'b1;
				next_state = VALID;
			end
		end
		VALID: begin
			vld = 1'b1;
			next_state = WAIT;
		end
		// Defaults to INIT1
		default: begin
			cmd = ENABLE_INT;
			if (&timer) begin
				wrt = 1'b1;
				next_state = INIT2;
			end
		end
	endcase
end
  
endmodule
	  