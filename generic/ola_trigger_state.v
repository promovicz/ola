
module ola_trigger_state
  (
   /* basic signals */
   reset, clock,

   /* control interface, synchronous */
   ctl_enable,
   ctl_data,
   ctl_then,
   ctl_else,
   ctl_conditions,
   ctl_actions,

   /* condition input, combinatorial */
   in_conditions,

   /* action output, combinatorial */
   out_act,
   out_actions
   );

   /* public parameters */
   parameter condition_width = 4;
   parameter action_width = 4;

   /* basic signals */
   input reset, clock;

   /* control inputs, synchronous */
   input ctl_enable, ctl_data;
   input ctl_then, ctl_else;
   input ctl_conditions, ctl_actions;

   /* condition input, combinatorial */
   input [condition_width-1:0] in_conditions;

   /* action output, combinatorial */
   output                    out_act;
   output [action_width-1:0] out_actions;

   /* condition and action registers */
   reg [condition_width-1:0] r_then_conditions;
   reg [action_width-1:0] 	 r_then_actions;
   reg [condition_width-1:0] r_else_conditions;
   reg [action_width-1:0] 	 r_else_actions;

   /* debug flag: dump state when leaving control mode */
   reg 						 do_dump;

   /* control interface implementation */
   always @(posedge clock or posedge reset)
	 if(reset) begin
		do_dump <= 0;
		r_then_actions <= 0;
		r_then_conditions <= 0;
		r_else_actions <= 0;
		r_else_conditions <= 0;
	 end else begin
		if(ctl_enable) begin
		   if(ctl_then) begin
			  if(ctl_conditions) begin
				 r_then_conditions[condition_width-1] <= ctl_data;
				 r_then_conditions[condition_width-2:0]
				   <= r_then_conditions[condition_width-1:1];
			  end
			  if(ctl_actions) begin
				 r_then_actions[action_width-1] <= ctl_data;
				 r_then_actions[action_width-2:0]
				   <= r_then_actions[action_width-1:1];
			  end
		   end
		   if(ctl_else) begin
			  if(ctl_conditions) begin
				 r_else_conditions[condition_width-1] <= ctl_data;
				 r_else_conditions[condition_width-2:0]
				   <= r_else_conditions[condition_width-1:1];
			  end
			  if(ctl_actions) begin
				 r_else_actions[action_width-1] <= ctl_data;
				 r_else_actions[action_width-2:0]
				   <= r_else_actions[action_width-1:1];
			  end
		   end
		   do_dump <= 1;
		end else begin
		   do_dump <= 0;
		   if(do_dump) begin
			  $display("[%10t] state ta %b tc %b ea %b ec %b",
					   $time,
					   r_then_actions, r_then_conditions,
					   r_else_actions, r_else_conditions);
		   end
		end
	 end

   /* combinatorial analyzer */
   wire then_act
		= (r_then_conditions != 0)
		&& ((in_conditions & r_then_conditions) == r_then_conditions);   
   wire else_act
		= (r_else_conditions != 0)
		&& ((in_conditions & r_else_conditions) == r_else_conditions);
   wire out_act
		= then_act || else_act;
   wire [action_width-1:0] out_actions
		= then_act ? r_then_actions : r_else_actions;
   
endmodule // ola_trigger_state

