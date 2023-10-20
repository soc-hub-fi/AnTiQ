verilator --cc  ../src/array_pq/pq_pkg.svh \
		../src/array_pq/pq_cell_fsm.sv \
		../src/array_pq/pq_cell.sv \
		../src/array_pq/pq.sv

RESULT=$?
if [ $RESULT -eq 0 ]; then
  echo Sources compiled
else
  echo Compilation failed
fi