
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

module ola_trigger_state(reset, clock);

   input reset, clock;
   
endmodule // ola_trigger_state

module ola_trigger_engine(reset, clock,

						  in_valid,
						  in_sample,
						  in_falling,
						  in_rising,

						  out_valid,
						  out_sample,
						  out_trigger);

   parameter sample_width = 8;
   
   parameter state_width = 2;
   parameter state_count = 4;

   parameter value_condition_width = 2 * sample_width;
   parameter edge_condition_width = 2 * sample_width;

   parameter condition_width
	 = value_condition_width
	   + edge_condition_width
	   ;
   
   /* trigger strobe */
   parameter trigger_action_width = 1;
   parameter trigger_action_offset = 0;
   /* state strobe and number */
   parameter state_action_width = 1 + state_width;
   parameter state_action_offset = trigger_action_width;
   
   parameter action_width
	 = trigger_action_width
	   + state_action_width
	   ;

   input reset, clock;

   input                    in_valid;
   input [sample_width-1:0] in_sample;
   input [sample_width-1:0] in_falling;
   input [sample_width-1:0] in_rising;

   output 					 out_valid;
   output [sample_width-1:0] out_sample;
   output 					 out_trigger;

   wire 				   all_act     [0:state_count-1];
   wire [action_width-1:0] all_actions [0:state_count-1];
   
   reg [state_width-1:0] cur_state;

   wire 				 cur_act = all_act[cur_state];
   wire [action_width-1:0] cur_actions = all_actions[cur_state];

   wire cur_action_trigger = cur_actions[trigger_action_offset+:trigger_action_width];
   wire cur_action_trigger_strobe = cur_action_trigger;
   
   wire [state_action_width-1:0] cur_action_state = cur_actions[state_action_offset+:state_action_width];
   wire 						 cur_action_state_strobe = cur_action_state[0];
   wire [state_width-1:0] 		 cur_action_state_number = cur_action_state[1+:state_width];

   genvar i;
   generate
	  for(i = 0; i < state_count; i = i + 1)
		begin
		   ola_trigger_state state (
									reset, clock
									);
		end
   endgenerate

   reg                    r_valid;
   reg [sample_width-1:0] r_sample;
   reg 					  r_trigger;
   
   always @(posedge clock or posedge reset)
	 if(reset) begin
		cur_state <= 0;
	 end else begin
		r_valid <= in_valid;
		r_sample <= in_sample;
		if(in_valid && cur_act) begin
		   if(cur_action_trigger_strobe) begin
			  r_trigger <= 1;
		   end
		   if(cur_action_state_strobe) begin
			  cur_state <= cur_action_state_number;
		   end
		end else begin
		   r_trigger <= 0;
		end
	 end
   
endmodule // ola_trigger_engine

module ola_trigger(reset, clock,
				   
				   in_valid,
				   in_sample,
				   in_time,

				   out_valid,
				   out_sample,
				   out_trigger
				   );
   
   parameter sample_width = 8;
   parameter time_width   = 32;

   input reset, clock;

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
   
   ola_trigger_values t_values
	 (
	  .reset(reset),
	  .clock(clock),
	  .in_valid(in_valid),
	  .in_sample(in_sample),
	  .out_valid(a_valid),
	  .out_sample(a_sample)
	  );
   
   ola_trigger_edges t_edges
	 (
	  .reset(reset),
	  .clock(clock),
	  .in_valid(in_valid),
	  .in_sample(in_sample),
	  .out_falling(a_falling),
	  .out_rising(a_rising)
	  );

   ola_trigger_engine t_engine
	 (
	  .reset(reset),
	  .clock(clock),
	  .in_valid(a_valid),
	  .in_sample(a_sample),
	  .in_falling(a_falling),
	  .in_rising(a_rising),
	  .out_valid(out_valid),
	  .out_sample(out_sample),
	  .out_trigger(out_trigger)
	  );
   
endmodule // ola_trigger
