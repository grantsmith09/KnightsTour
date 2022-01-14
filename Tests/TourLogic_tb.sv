module TourLogic_tb();

logic clk, rst_n, go, done;
logic [2:0] x_start, y_start;
logic [4:0] indx;
logic [7:0] move;
logic [3:0] i;
logic [3:0] test;
logic [2:0] x_test[0:12];
logic [2:0] y_test[0:12];
TourLogic iDUT(.clk,.rst_n,.x_start,.y_start,.go,.done,.indx,.move);

initial begin 
x_test = {3'b000, 3'b010, 3'b100, 3'b001, 3'b011, 3'b000, 3'b010, 3'b100, 
			3'b001, 3'b011, 3'b000, 3'b010, 3'b100};
y_test = {3'b000, 3'b000, 3'b000, 3'b001, 3'b001, 3'b010, 3'b010, 3'b010, 
			3'b011, 3'b011, 3'b100, 3'b100, 3'b100};

clk = 0;



for(i = 1'b0; i <= 4'b1100; i = i+1'b1) begin
	
test = {i};
rst_n = 0;
x_start = x_test[i];
y_start = y_test[i];
@(posedge clk);
@(negedge clk);
rst_n = 1;
go = 1;
@(negedge clk);
go = 0;

 fork
	
	begin : testDone
		
		repeat(10000000) @(posedge clk);
		$display("ERROR: done never asserted on test %d %d", x_start, y_start );
		
		
		disable testGood;
	end
	begin : testGood
		@(posedge done);
		$display("Test Complete %d %d at time %0t", x_start, y_start, $time );
		disable testDone;
	end
join
continue;

end




$display("YAHOOO: TEST PASSED!!!!");
$stop();

end

always
	#5 clk = ~clk;

endmodule
