
module ola_trigger_countdown(reset, clock,

							 in_valid,
							 in_run,
							 in_setup,
							 in_value,
							 
							 out_expired
							 );

   parameter width = 32;

   input reset, clock;

   input             in_valid;
   input             in_run;
   input             in_setup;
   input [width-1:0] in_value;

   output 			 out_expired;
   
   reg [width-1:0] counter;
   reg 			   expired;

   wire 		   out_expired = expired;
   
   always @(posedge clock or posedge reset)
	 if(reset)
	   begin
		  counter <= 0;
		  expired <= 0;
	   end
	 else
	   if(in_valid && in_run)
		 begin
			/* expire synchronously when done */
			if(counter == 1)
			  expired <= 1;
			else
			  expired <= 0;
			/* decrement or load counter */
			if(in_setup)
			  counter <= in_value;
			else
			  counter <= counter - 1;
		 end

endmodule // ola_trigger_countdown

