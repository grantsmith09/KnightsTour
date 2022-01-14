module SPI_mnrch(clk, rst_n, SS_n, SCLK, MOSI, MISO, wrt, wt_data, done, rd_data);

input logic clk, rst_n, MISO, wrt;//Clock, reset, monarch in serf out, write
output logic SS_n, SCLK, MOSI; //Chip Select, SClK, Monarch out serf in
input logic  [15:0] wt_data; //write data
output logic done;
output logic [15:0] rd_data; //read data


logic [3:0] bit_cntr; //bit count
logic done15; //done 15 shifts
logic init; // initalization
logic set_done; //set done
logic shft;//shifts
logic smpl; //sample
logic ld_SCLK; //load SCLK

//Bit_Cntr
always_ff@(posedge clk)
	if(init)
		bit_cntr <= 4'h0;
	else if(shft)
		bit_cntr <= bit_cntr + 1;
	else
		bit_cntr <= bit_cntr;
		
assign done15 = &bit_cntr;


//SCLK
logic [4:0] SCLK_div;

always_ff@(posedge clk) begin
	if(ld_SCLK)
		SCLK_div <= 5'b10111;
	else
		SCLK_div <= SCLK_div + 1;
	SCLK <= SCLK_div[4];
	end

logic smpl_imm, shft_imm;
	
//USED BY STATE MACHINE TO ASSERT smpl and shft
assign smpl_imm = SCLK_div == 5'b01111 ? 1'b1 : 1'b0; //sample next clk
assign shft_imm = SCLK_div == 5'b11111 ? 1'b1 : 1'b0; //shift next clk


//MISO MOSI Implementation
logic MISO_smpl;

always_ff@(posedge clk)
	if(smpl)
		MISO_smpl <= MISO;
	else 
		MISO_smpl <= MISO_smpl;
		
logic [15:0] shft_reg;

//shift MISO in
always_ff@(posedge clk) begin
	if(init)
		shft_reg <= wt_data;
	else if (shft)
		shft_reg <= {shft_reg[14:0], MISO_smpl};
	else
		shft_reg <= shft_reg;
	end
assign MOSI = shft_reg[15];	 //Shift out highest bit
assign rd_data = shft_reg;


//State Machine
typedef enum reg [1:0] {IDLE, FRONT, WORK, BACK} state_t;

state_t state, nxt_state;

always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;

always_comb begin	
	//Default Values
	init = 1'b0;
	shft = 1'b0;
	smpl = 1'b0;
	nxt_state = state;
	ld_SCLK = 1'b0;
	set_done = 1'b0;
	
	case(state)
		IDLE: if(wrt) begin
				init = 1'b1;
				ld_SCLK = 1'b1;
				nxt_state = FRONT;
			end
			else begin
				ld_SCLK = 1'b1;
			end
		FRONT: if(shft_imm) begin
					nxt_state = WORK;
			   end
		WORK: if(shft_imm) begin
					shft = 1'b1;
			  end
			  else if(smpl_imm) begin
					smpl = 1'b1;
			  end
			  else if(done15) begin
					nxt_state = BACK;
					ld_SCLK = 1'b1;
			  end
		BACK: if(smpl_imm) begin
					smpl = 1'b1;
			  end
			  else if(shft_imm) begin
						shft = 1'b1;
						ld_SCLK = 1'b1;
						set_done = 1'b1;
						nxt_state = IDLE;
					end
		endcase
		
	end
		
		
//Done and SS_n Flops
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		done <= 1'b0;
	else if(init)
		done <= 1'b0;
	else if(set_done)
		done <= 1'b1;
		
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		SS_n <= 1'b1;
	else if(init)
		SS_n <= 1'b0;
	else if(set_done)
		SS_n <= 1'b1;
		
endmodule
