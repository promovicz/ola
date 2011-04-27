
module ola_trigger_edges(reset, clock,
						 
						 in_valid,
						 in_sample,
						 
						 out_falling,
						 out_rising
						 );

   parameter width = 8;

   input reset, clock;
   
   input             in_valid;
   input [width-1:0] in_sample;

   output [width-1:0] out_falling;
   output [width-1:0] out_rising;
   
   reg             prev_valid;
   reg [width-1:0] prev_sample;

   reg [width-1:0] falling;
   reg [width-1:0] rising;

   wire 		   out_falling = falling;
   wire 		   out_rising = rising;
   
   always @(posedge clock or posedge reset)
	 if(reset) begin
		prev_valid  <= 0;
		prev_sample <= 0;
	 end else begin
		/* update state */
		prev_valid <= in_valid;
		prev_sample <= in_sample;
		/* if we can, indicate edges */
		if(prev_valid) begin
		   rising <= in_sample & ~prev_sample;
		   falling <= prev_sample & ~in_sample;
		end else begin
		   rising <= 0;
		   falling <= 0;
		end
	 end
   
endmodule // ola_trigger_edges
