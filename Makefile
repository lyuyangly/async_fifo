# Makefile For VCS

all:
	@echo "VCS Verification ENV"

verdi:
	@verdi -sverilog async_fifo_tb.sv async_fifo.v &

cmp:
	@vcs -LDFLAGS -Wl,--no-as-needed -debug_all +lint=TFIPC-L +lint=PCWM -P ${NOVAS_HOME}/share/PLI/VCS/LINUX/novas.tab ${NOVAS_HOME}/share/PLI/VCS/LINUX/pli.a -sverilog async_fifo_tb.sv async_fifo.v -l vcs.log

run:
	@./simv -l simv.log

dve:
	@dve -vpd wave.vpd &

clean:
	@rm -rf ucli.key csrc simv simv.daidir vcs.log simv.log DVEfiles wave.fsdb novas_dump.log verdiLog nWaveLog

