
module ola_trigger_engine(reset, clock,

						  ctl_enable, ctl_data,
						  
						  ctl_state_which,
						  ctl_state_what,
						  
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

   parameter state_ctl_width = 2;
   parameter state_ctl_count = 4;

   /* CONDITION STRUCTURE */
   
   /* value and inverted value */
   parameter value_condition_width = 2 * sample_width;
   /* falling and rising edges */
   parameter edge_condition_width = 2 * sample_width;

   /* condition structure from lsb to msb */
   parameter condition_width
	 = value_condition_width
	   + edge_condition_width
	   ;

   /* ACTION STRUCTURE */
   
   /* trigger strobe */
   parameter trigger_action_width = 1;
   parameter trigger_action_offset = 0;
   /* state strobe and number */
   parameter state_action_width = 1 + state_width;
   parameter state_action_offset = trigger_action_width;

   /* action structure from lsb to msb */
   parameter action_width
	 = trigger_action_width
	   + state_action_width
	   ;

   /* I/O SIGNALS */
   
   /* basic signals */
   input reset, clock;

   /* control feed */
   input                   ctl_enable;
   input 				   ctl_data;
   
   input [state_width-1:0] ctl_state_which;
   input [state_ctl_width-1:0] ctl_state_what;
   
   /* sample feed */
   input                    in_valid;
   input [sample_width-1:0] in_sample;
   input [sample_width-1:0] in_falling;
   input [sample_width-1:0] in_rising;

   /* result feed */
   output 					 out_valid;
   output [sample_width-1:0] out_sample;
   output 					 out_trigger;

   /* STATE REGISTER */
   reg [state_width-1:0]   cur_state;

   /* STATE SIGNALS */
   wire 				   all_act     [0:state_count-1];
   wire [action_width-1:0] all_actions [0:state_count-1];
   
   /* STATE DEMUX */
   wire cur_act
	  = all_act[cur_state];
   wire [action_width-1:0] cur_actions
	  = all_actions[cur_state];

   /* ACTION DEMUX */
   
   /* trigger action */
   wire cur_action_trigger
	  = cur_actions[trigger_action_offset+:trigger_action_width];
   wire cur_action_trigger_strobe
	  = cur_action_trigger;

   /* state action */
   wire [state_action_width-1:0] cur_action_state
	  = cur_actions[state_action_offset+:state_action_width];
   wire cur_action_state_strobe
	  = cur_action_state[0];
   wire [state_width-1:0] cur_action_state_number
	  = cur_action_state[1+:state_width];

   /* CONDITION MUX */
   wire [condition_width-1:0] conditions
	  = {in_rising, in_falling, ~in_sample, in_sample};

   /* COMBINATORIAL STATES */
   wire state_ctl_sel_then       = ctl_state_what == 0 || ctl_state_what == 2;
   wire state_ctl_sel_else       = ctl_state_what == 1 || ctl_state_what == 3;
   wire state_ctl_sel_actions    = ctl_state_what == 0 || ctl_state_what == 1;
   wire state_ctl_sel_conditions = ctl_state_what == 2 || ctl_state_what == 3;
   genvar i;
   generate
	  for(i = 0; i < state_count; i = i + 1)
		begin
		   wire state_ctl_enable
				= ctl_enable && (ctl_state_which == i);
		   ola_trigger_state
			 #(
			   .action_width(action_width),
			   .condition_width(condition_width)
			   )
		   state
			   (
				.reset(reset),
				.clock(clock),

				.ctl_enable(state_ctl_enable),
				.ctl_data(ctl_data),
				.ctl_then(state_ctl_sel_then),
				.ctl_else(state_ctl_sel_else),
				.ctl_actions(state_ctl_sel_actions),
				.ctl_conditions(state_ctl_sel_conditions),
				
				.in_conditions(conditions),
				
				.out_act(all_act[i]),
				.out_actions(all_actions[i])
				);
		end
   endgenerate

   /* OUTPUT REGISTERS */
   reg                    r_valid;
   reg [sample_width-1:0] r_sample;
   reg 					  r_trigger;

   wire 				   out_valid = r_valid;
   wire [sample_width-1:0] out_sample = r_sample;
   wire 				   out_trigger = r_trigger;

   /* STATE MACHINE */
   always @(posedge clock or posedge reset)
	 if(reset) begin
		cur_state <= 0;
	 end else begin
		if(!ctl_enable) begin
		   r_valid <= in_valid;
		   r_sample <= in_sample;
		   if(in_valid) begin
			  $display("[%10t] trigger sample %b falling %b rising %b",
					   $time, in_sample, in_falling, in_rising);
		   end
		   if(cur_act) begin
			  if(in_valid) begin
				 if(cur_action_trigger_strobe) begin
					$display("[%10t] raising trigger signal", $time);
					r_trigger <= 1;
				 end
				 if(cur_action_state_strobe) begin
					$display("[%10t] switching state from %d to %d",
							 $time, cur_state, cur_action_state_number);
					cur_state <= cur_action_state_number;
				 end
			  end
		   end else begin
			  r_trigger <= 0;
		   end
		end
	 end
   
endmodule // ola_trigger_engine

