module charge(clk, rst_n, go, piezo, piezo_n);

input logic clk, rst_n, go;
output logic piezo, piezo_n;
parameter FAST_SIM = 1;


//intermediate counter values
logic [24:0] duration;
logic [24:0] current_dur;
logic dur_done, rst_count;

//duration counter
always_ff@(posedge clk)
	if(rst_count)
		current_dur <= '0;
	else begin
		if(FAST_SIM) begin 
			current_dur <= current_dur + 16;
		end
		else begin
			current_dur <= current_dur + 1;
		end
	end


assign dur_done = duration == current_dur? 1'b1: 1'b0;


//frequency timer

logic [15:0] total_freq;
logic [15:0] freq_70;
logic [15:0] cur_freq;
logic rst_freq;
logic rst_freq_start;

always_ff@(posedge clk)
	if(rst_freq_start)
		cur_freq <= '0;
	else if(rst_freq)
		cur_freq <= '0;
	else 
		cur_freq <= cur_freq + 1;
		

//frequency logic
assign piezo = cur_freq <= freq_70? 1'b1: 1'b0;
assign piezo_n = ~piezo;
assign rst_freq = cur_freq == total_freq? 1'b1: 1'b0;


typedef enum reg [2:0] {IDLE, G6, C7, E7, G7, E72, G72} SM_state;
SM_state state, next_state;
localparam dur_23 = 25'h0800000;//2^23
localparam dur_24 = 25'h1000000;//2^24
localparam dur_23_22 = 25'h0C00000;//2^23 + 2^22
localparam dur_22 = 25'h400000;//2^22
localparam G6_freq = 16'h7C8F; // 31887 clocks
localparam C7_freq = 16'h5D51; // 23889 clocks
localparam E7_freq = 16'd18960;
localparam G7_freq = 16'd15944; 
// Register holding current state
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		state <= IDLE;
	else
		state <= next_state;
		
always_comb begin
	rst_count = 1'b0;
	rst_freq_start = 1'b0;
	duration = '0;
	total_freq = '0;
	freq_70 = '0;
	next_state = state;
	case(state)
	G6: begin
		duration = dur_23;
		total_freq = G6_freq;
		freq_70 = G6_freq * 0.7;
		if(dur_done) begin
			rst_count = 1'b1;
			rst_freq_start = 1'b1;
			next_state = C7;
		end
	end
	C7:begin
		duration = dur_23;
		total_freq = C7_freq;
		freq_70 = C7_freq * 0.7;
		if(dur_done) begin
			rst_count = 1'b1;
			rst_freq_start= 1'b1;
			next_state = E7;
		end
	end
	E7:begin
		duration = dur_23;
		total_freq = E7_freq;
		freq_70 = E7_freq * 0.7;
		if(dur_done) begin
			rst_count = 1'b1;
			rst_freq_start= 1'b1;
			next_state = G7;
		end
	end
	G7:begin
		duration = dur_23_22;
		total_freq = G7_freq;
		freq_70 = G7_freq * 0.7;
		if(dur_done) begin
			rst_count = 1'b1;
			rst_freq_start= 1'b1;
			next_state = E72;
		end
	end
	E72:begin
		duration = dur_22;
		total_freq = E7_freq;
		freq_70 = E7_freq * 0.7;
		if(dur_done) begin
			rst_count = 1'b1;
			rst_freq_start= 1'b1;
			next_state = G72;
		end
	end
	G72:begin
		duration = dur_24;
		total_freq = G7_freq;
		freq_70 = G7_freq * 0.7;
		if(dur_done) begin
			rst_count = 1'b1;
			rst_freq_start= 1'b1;
			next_state = IDLE;
		end
	end
	default: begin
		if(go) begin
			rst_count = 1'b1;
			rst_freq_start= 1'b1;
			next_state = G6;
		end
	end
	endcase
end
		
endmodule
`default_nettype wire
