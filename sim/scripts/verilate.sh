verilator --cc  ../src/array_pq/pq_pkg.svh \
		../src/array_pq/pq_cell_fsm.sv \
		../src/array_pq/pq_cell.sv \
		../src/array_pq/pq.sv \
		--top-module pq \
		-Wall --trace --exe ../verilator/tb_pq.cc

make -C obj_dir -f Vpq.mk Vpq

RESULT=$?
if [ $RESULT -eq 0 ]; then
  echo Sources compiled
else
  echo Compilation failed
fi