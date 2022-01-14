/*
Group: Knights of Square Table
Tour Logic SM
Date: 12/11/21
*/
module TourLogicSM(clk, rst_n, go, done, moveNumDone, moveRem, initSig, solveMove, initBoard, goBack, prevGood, noMove, poss, newMove);

input go, clk, rst_n, moveRem, noMove, prevGood, newMove;
output logic done, initSig, goBack, solveMove, initBoard, poss;
input logic moveNumDone;

typedef enum reg[2:0]{IDLE,INIT,NEW,SOLVE,BACKUP,DONE} state_t;
  state_t state, nxt_state;

  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;

  always_comb begin
    //Default SM outputs
	poss = 0;
	initSig = 0;
	solveMove = 0;
	goBack = 0;
    done = 0;
    initBoard = 0;
    nxt_state = state;
 

    case (state)
	  INIT : begin
		initSig = 1;
		nxt_state = NEW;
	  end
		
	  NEW : if(newMove)begin
		poss = 1;
		nxt_state = SOLVE;
	  end
	  
	  SOLVE : if(moveRem) begin
		solveMove = 1;
	  end else if(moveNumDone) begin
		nxt_state = DONE;
	  end else if(noMove)begin
		nxt_state = BACKUP;
	  end else if(newMove)begin
		nxt_state = NEW;
	  end
	  
	  BACKUP : if(prevGood) begin
		nxt_state = SOLVE;
	  end else begin 
		goBack = 1;
	  end

      DONE : begin
        done = 1;
        nxt_state = IDLE;
      end 

      

      //Default case is IDLE
      default : if(go) begin
		initBoard = 1;
        nxt_state = INIT;
        end 
    endcase
    end
endmodule