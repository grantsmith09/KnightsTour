/*
Group: Knights of Square Table
Tour Logic
Date: 12/11/21
*/
module TourLogic(clk,rst_n,x_start,y_start,go,done,indx,move);
  input clk,rst_n;				// 50MHz clock and active low asynch reset
  input [2:0] x_start, y_start;	// starting position on 5x5 board
  input go;						// initiate calculation of solution
  input [4:0] indx;				// used to specify index of move to read out
  output logic done;			// pulses high for 1 clock when solution complete
  output logic [7:0] move;			// the move addressed by indx (1 of 24 moves)

  ////////////////////////////////////////
  // Declare needed internal registers //
  //////////////////////////////////////
	logic visited [0:4][0:4]; //The board and what has been visited
	logic [7:0] lastMove [0:23]; //All of the previosu moves, with the first move in pos 0
	logic [7:0] possMove [0:23]; //8 bit 1 hot vector for each position on the board and the poss moves
	logic [7:0] tryMove; //move to try
	logic [4:0] moveNum; //The number of move that we are one.
	logic [2:0] currX, currY; //curr location of the knight (xx,yy) 
	//Control signals coming from state machine to control logic blocks
	logic solveMove, initSig, initBoard, prevGood, goBack, poss;
	//Signals going to state machine to control states
	logic newMove, moveRem, noMove, moveNumDone;
	//Init of State Machine
	TourLogicSM sm(.clk, .rst_n, .go, .done, .moveNumDone, .moveRem, .initSig, .solveMove, .initBoard, 
	 .goBack, .prevGood, .noMove, .poss, .newMove);


  function [7:0] calc_poss(input [2:0] xpos,ypos);
    ///////////////////////////////////////////////////
	// Consider writing a function that returns a packed byte of
	// all the possible moves (at least in bound) moves given
	// coordinates of Knight.
	/////////////////////////////////////////////////////
	//if the square resulting from move 0 is taken, mark the move as not possible 
	
	logic [7:0] try;
	integer i;
	try = 8'h01;
	calc_poss = 8'h00;
	for(i = 0; i <= 7; i++) begin
		
		if((off_x(try) + xpos <= 3'b100) && (off_x(try) + xpos >= 3'b000) && 
			(off_y(try) + ypos <= 3'b100) && (off_y(try) + ypos >= 3'b000)) begin
		  if(visited[off_x(try) + xpos][off_y(try) + ypos] == 1'b0) begin
			
				calc_poss[i] = 1'b1;
			end
		end
		try = try<<1;
	end
	return calc_poss;
  endfunction

function signed [2:0] off_x(input [7:0] try);
    ///////////////////////////////////////////////////
	// Consider writing a function that returns a the x-offset
	// the Knight will move given the encoding of the move you
	// are going to try.  Can also be useful when backing up
	// by passing in last move you did try, and subtracting 
	// the resulting offset from xx
	/////////////////////////////////////////////////////
	if(try[0] || try[4])
		off_x = 3'b111;
	else if(try[1] || try[5]) 
		off_x = 3'b001;
	else if(try[6] || try[7])
		off_x = 3'b010;
	else
		off_x = 3'b110;
	
	
	
  endfunction
  
  function signed [2:0] off_y(input [7:0] try);
    ///////////////////////////////////////////////////
	// Consider writing a function that returns a the y-offset
	// the Knight will move given the encoding of the move you
	// are going to try.  Can also be useful when backing up
	// by passing in last move you did try, and subtracting 
	// the resulting offset from yy
	/////////////////////////////////////////////////////
	if(try[0] || try[1])
		off_y = 3'b010;
	else if(try[4] || try[5])
		off_y = 3'b110;
	else if(try[2] || try[7])
		off_y = 3'b001;
	else
		off_y = 3'b111;

  endfunction


  
  //Solving the board 
  always_ff @(posedge clk) begin
  
	//IDLE STATE
	//Init the the board and some of the control signals
	if(initBoard) begin
	
		visited = '{'{1'b0, 1'b0, 1'b0, 1'b0, 1'b0},
		'{1'b0, 1'b0, 1'b0, 1'b0, 1'b0},
		'{1'b0, 1'b0, 1'b0, 1'b0, 1'b0},
		'{1'b0, 1'b0, 1'b0, 1'b0, 1'b0},
		'{1'b0, 1'b0, 1'b0, 1'b0, 1'b0}};
		moveNum = '0;
		moveNumDone = 1'b0;
		newMove = 1'b1;
		
	end
	
	//INIT STATE
	if(initSig) begin
		visited[x_start][y_start] = 1'b1;
		currX = x_start;
		currY = y_start;
		
	end
		
	//NEW STATE
	if(poss) begin
			possMove[moveNum] = calc_poss(currX, currY);
			tryMove = 8'h01;
			visited[currX][currY] = 1'b1;
			moveRem = 1;
				
				
			newMove = 0;	
	end
	
	
	
	//SOLVE STATE 
		if(solveMove) begin
			//If a move is possible 
			if((possMove[moveNum] & tryMove) != 8'h00) begin
				moveRem = 0;
				lastMove[moveNum] = tryMove;
				currX = currX + off_x(tryMove);
				currY = currY + off_y(tryMove);
				moveNum = moveNum + 1'b1;
				//Gives control to the new state 
				newMove = 1;
				
				//Gives control to the done state if board is complete
				if(moveNum == 5'b11000)begin
					moveNumDone = 1;
					end
					
			end else if(possMove[moveNum] == 8'h00)begin
				//gives control to the backup state 
				moveRem = 0;
				noMove = 1;
			
			end else if(tryMove != 8'h80) begin //Checks if the next move is poss
				tryMove = tryMove<<1;
			end else begin
				//gives control to the backup state
				moveRem = 0;
				noMove = 1;
			end
			//holds control from the new state
			prevGood = 0;
		end	
			
			
			
			
	//BACKUP STATE
	if(goBack) begin	
		
			visited[currX][currY] = 1'b0;
			moveNum = moveNum - 1'b1;
			currX = currX - off_x(lastMove[moveNum]);
			currY = currY - off_y(lastMove[moveNum]);
			tryMove = lastMove[moveNum];
			possMove[moveNum] = possMove[moveNum] & ~tryMove;
			tryMove = tryMove << 1;
			
			//Returns control back to the solve state
			moveRem = 1;
			prevGood = 1;
			//Holds control from new and backup states 
			newMove = 0;
			noMove = 0;
			
		
	end	
	
	end 
  

//Controls the replay of the board solution after it has been completed
	assign move = lastMove[indx];



endmodule