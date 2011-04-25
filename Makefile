
IVER?=iverilog
IVVP?=vvp

default: la.vvp

run: la.vvp
	$(IVVP) la.vvp

la.vvp: la.v

%.vvp: %.v
	$(IVER) -t vvp -o $@ $<

clean:
	rm -f la.vvp
