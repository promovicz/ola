module ola_trigger(reset, clock,

				   ctl_enable,
				   ctl_data,
				   ctl_state_which,
				   ctl_state_what,
				   
				   in_valid,
				   in_sample,
				   in_time,

				   out_valid,
				   out_sample,
				   out_trigger
				   );
   
   parameter sample_width = 8;
   parameter time_width   = 32;

   parameter state_sel_width = 2;
   parameter state_sel_count = 4;

   parameter state_reg_width = 2;
   parameter state_reg_count = 4;

   /* basic signals */
   input reset, clock;

   /* control signals */
   input ctl_enable;
   input ctl_data;
   input [state_sel_width-1:0] ctl_state_which;
   input [state_reg_width-1:0] ctl_state_what;
   
   /* input stage signals */
   input                    in_valid;
   input [sample_width-1:0] in_sample;
   input [time_width-1:0] 	in_time;

   /* analysed stage signals */
   wire 					a_valid;
   wire [sample_width-1:0] 	a_sample;
   wire [sample_width-1:0] 	a_falling;
   wire [sample_width-1:0] 	a_rising;

   /* recording stage signals */
   output 					 out_valid;
   output [sample_width-1:0] out_sample;
   output 					 out_trigger;

   ola_trigger_values
	 #(
	   .width(sample_width)
	   )
   t_values
	 (
	  .reset(reset),
	  .clock(clock),
	  .in_valid(in_valid),
	  .in_sample(in_sample),
	  .out_valid(a_valid),
	  .out_sample(a_sample)
	  );
   
   ola_trigger_edges
	 #(
	   .width(sample_width)
	   )
   t_edges
	 (
	  .reset(reset),
	  .clock(clock),
	  .in_valid(in_valid),
	  .in_sample(in_sample),
	  .out_falling(a_falling),
	  .out_rising(a_rising)
	  );

   ola_trigger_engine
	 #(
	   .sample_width(sample_width)
	   )
   t_engine
	 (
	  .reset(reset),
	  .clock(clock),
	  
	  .ctl_enable(ctl_enable),
	  .ctl_data(ctl_data),
	  .ctl_state_which(ctl_state_which),
	  .ctl_state_what(ctl_state_what),
	  
	  .in_valid(a_valid),
	  .in_sample(a_sample),
	  .in_falling(a_falling),
	  .in_rising(a_rising),
	  
	  .out_valid(out_valid),
	  .out_sample(out_sample),
	  .out_trigger(out_trigger)
	  );
   
endmodule // ola_trigger
