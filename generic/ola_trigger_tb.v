
module ola_trigger_tb();

   /* holding registers */
   reg reset;
   reg clock;

   /* generate initial reset */
   initial begin
	  $display("[%10t] Resetting...", $time);
	  # 5 reset = 1;
	  # 5 reset = 0;
   end

   /* generate master clock */
   initial begin
	  clock = 0;
   end
   always #1 clock = !clock;

   /* terminate after a while */
   initial begin
	  #1000 $finish;
   end

   /* analyzer parameters */
   parameter sample_width = 4;
   parameter time_width = 32;

   /* generated sample stream */
   reg [time_width-1:0]   sig_time;
   reg                    sig_valid;
   reg [sample_width-1:0] sig_sample;

   /* sample stream generator */
   initial begin
	  sig_valid = 0;
	  sig_time = 0;
	  sig_sample = 0;
   end
   always # 10
	 if (sig_valid) begin
		sig_sample = sig_sample + 1;
		sig_time = sig_time + 1;
	 end

   parameter step_width = 8;
   parameter step_count = 256;
   
   parameter state_bit_width = 8;
   parameter state_bit_count = 256;

   parameter state_sel_width = 2;
   parameter state_sel_count = 4;

   parameter state_reg_width = 2;
   parameter state_reg_count = 4;

   reg [step_width-1:0] r_ctl_step;
   reg r_ctl_enable;
   reg r_ctl_data;
   reg [state_sel_width-1:0] r_ctl_which;
   reg [state_reg_width-1:0] r_ctl_what;

   reg [state_bit_count-1:0] r_ctl_reg;
   reg [state_bit_width-1:0] r_ctl_count;

   always @(posedge clock or posedge reset)
	 if (reset) begin
		r_ctl_step <= 0;
		r_ctl_enable <= 0;
		r_ctl_count <= 0;
	 end else begin
		if(r_ctl_enable) begin
		   if(r_ctl_count > 0) begin
			  r_ctl_data <= r_ctl_reg[0];
			  r_ctl_reg[state_bit_count-2:0]
				= r_ctl_reg[state_bit_count-1:1];
			  r_ctl_count <= r_ctl_count - 1;
		   end else begin
			  $display("[%10t] wrote to state %d reg %d",
					   $time, r_ctl_which, r_ctl_what);
			  r_ctl_enable <= 0;
		   end
		end else begin
		   case(r_ctl_step)
			 0: begin
				r_ctl_reg <= 256'b0110;
				r_ctl_count <= 4;
				r_ctl_which <= 0;
				r_ctl_what <= 0;
				r_ctl_enable <= 1;
				r_ctl_step <= 1;
			 end
			 1: begin
				r_ctl_reg <= 256'b0000010000000000;
				r_ctl_count <= 16;
				r_ctl_which <= 0;
				r_ctl_what <= 2;
				r_ctl_enable <= 1;
				r_ctl_step <= 2;
			 end
			 2: begin
				r_ctl_reg <= 256'b0000;
				r_ctl_count <= 4;
				r_ctl_which <= 0;
				r_ctl_what <= 1;
				r_ctl_enable <= 1;
				r_ctl_step <= 3;
			 end
			 3: begin
				r_ctl_reg <= 256'b0000000000000000;
				r_ctl_count <= 16;
				r_ctl_which <= 0;
				r_ctl_what <= 3;
				r_ctl_enable <= 1;
				r_ctl_step <= 4;
			 end
			 4: begin
				r_ctl_reg <= 256'b0011;
				r_ctl_count <= 4;
				r_ctl_which <= 1;
				r_ctl_what <= 0;
				r_ctl_enable <= 1;
				r_ctl_step <= 5;
			 end
			 5: begin
				r_ctl_reg <= 256'b0000001000000000;
				r_ctl_count <= 16;
				r_ctl_which <= 1;
				r_ctl_what <= 2;
				r_ctl_enable <= 1;
				r_ctl_step <= 6;
			 end
			 6: begin
				$display("[%10t] starting sample stream...", $time);
				sig_valid = 1;
				r_ctl_step <= 255;
			 end
		   endcase

		end
	 end
   
   
   ola_trigger
	 #(
	   .sample_width(sample_width),
	   .time_width(time_width)
	   )
   trigger
	 (
	  .reset(reset),
	  .clock(clock),

	  .ctl_enable(r_ctl_enable),
	  .ctl_data(r_ctl_data),
	  .ctl_state_which(r_ctl_which),
	  .ctl_state_what(r_ctl_what),
	  
	  .in_valid(sig_valid),
	  .in_sample(sig_sample),
	  .in_time(sig_time),

	  .out_trigger(trigger)
	  );

   always @*
	 if(trigger) begin
		$display("Triggered!");
		#100
		  $finish;
	 end

   initial begin
	  $dumpfile("ola_trigger_tb.txt");
	  $dumpvars;
   end
   
endmodule // ola_trigger_tb
