module reset_synch(RST_n, clk, rst_n);

input RST_n, clk;
output reg rst_n;


//intermediate signal
reg intermediate_reset;

always@(negedge clk, negedge RST_n)
	if(!RST_n) begin
		intermediate_reset <= 1'b0;
		rst_n <= 1'b0;
	end
	else begin
		intermediate_reset <= 1'b1;
		rst_n <= intermediate_reset;
	end
	
endmodule 
