module charge_tb();

   reg go;//Go- Starts Fanfair
   reg  clk, rst_n;//CLcok, Reset

   wire piezo, piezo_n;//Piezo and Not Piezo Driving Signals

	//Instantiate Dut
	charge charge1(.clk(clk), .rst_n(rst_n), .go(go), .piezo(piezo), .piezo_n(piezo_n));


initial begin 
   clk = 0;
   rst_n = 0;
   go = 0;
   @(negedge clk); //deassert reset
   rst_n = 1; 
   @(posedge clk);
   go = 1;
   repeat(10) @(posedge clk); //Wait for signal to leave idle
   go = 0;
   
   	// Wait for Charge Fanfair
	repeat(10000000) @(posedge clk);
	$stop;
	
  

 end 


always
  #5 clk = ~clk;


endmodule
    
   