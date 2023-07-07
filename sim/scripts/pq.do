add log -r sim:/tb_pq_common/*
add wave -group "top"  -position insertpoint sim:/tb_pq_common/*
add wave -group "cell regs" -position insertpoint  \
{sim:/tb_pq_common/i_dut/cell_gen[0]/i_pq_cell/cell_r}
add wave -group "cell regs" -position insertpoint  \
{sim:/tb_pq_common/i_dut/cell_gen[1]/i_pq_cell/cell_r}
add wave -group "cell regs" -position insertpoint  \
{sim:/tb_pq_common/i_dut/cell_gen[2]/i_pq_cell/cell_r}


add wave -group "cell 0" -position insertpoint {sim:/tb_pq_common/i_dut/cell_gen[0]/i_pq_cell/i_fsm/*}
add wave -group "cell 0" -position insertpoint {sim:/tb_pq_common/i_dut/cell_gen[0]/i_pq_cell/*_struct_*}
add wave -group "cell 1" -position insertpoint {sim:/tb_pq_common/i_dut/cell_gen[1]/i_pq_cell/i_fsm/*}
add wave -group "cell 1" -position insertpoint {sim:/tb_pq_common/i_dut/cell_gen[1]/i_pq_cell/*_struct_*}
add wave -group "cell 2" -position insertpoint {sim:/tb_pq_common/i_dut/cell_gen[2]/i_pq_cell/i_fsm/*}
add wave -group "cell 2" -position insertpoint {sim:/tb_pq_common/i_dut/cell_gen[2]/i_pq_cell/*_struct_*}

configure wave -signalnamewidth 1
run 900 ns
wave zoom full

exit
