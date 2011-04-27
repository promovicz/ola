
module ola_trigger_values(reset, clock,
						  in_valid, in_sample,
						  out_valid, out_sample);
   parameter width = 8;

   input reset, clock;

   input             in_valid;
   input [width-1:0] in_sample;

   output 			  out_valid;
   output [width-1:0] out_sample;

   reg 				  valid;
   reg [width-1:0]	  sample;

   wire 			  out_valid = valid;
   wire 			  out_sample = sample;
   
   always @(posedge clock or posedge reset)
	 if(reset)
	   begin
		  valid <= 0;
		  sample <= 0;
	   end
	 else
	   begin
		  valid <= in_valid;
		  sample <= in_sample;
	   end
   
endmodule // ola_trigger_values
