
IVER?=iverilog
IVVP?=vvp

LA_VERILOG=							\
	generic/ola_timescale.v			\
	generic/ola_trigger_countdown.v	\
	generic/ola_trigger_edges.v		\
	generic/ola_trigger_engine.v	\
	generic/ola_trigger_state.v		\
	generic/ola_trigger_values.v	\
	generic/ola_trigger.v			\
	generic/ola_trigger_tb.v


default: la.vvp

run: la.vvp
	$(IVVP) -lxt2 la.vvp

la.vvp: $(LA_VERILOG)

%.vvp:
	$(IVER) -t vvp -o $@ $^

clean:
	rm -f la.vvp ola_trigger_tb.txt

