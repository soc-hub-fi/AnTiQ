
# ##############################################################################
# File     : synth.tcl
# Descr    : Create Vivado project and synthesize hw_pq design in a number of 
#            configurations for the VCU118.
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi> 
# ##############################################################################

 # PYNQ
#set FPGA_PART    "xc7z020clg400-1"
# VCU118
set FPGA_PART            "xcvu9p-flga2104-2L-e"
set FPGA_CLK_FREQ_MHZ    "250.000"
set DESIGN_CLK_FREQ_MHZ  "350.000"

set PROJECT      hw_pq_fpga
set VIVADO_VER   $::env(VIVADO_VERSION)
set PWD          "[pwd]"
set BUILD_DIR    "${PWD}"
set FPGA_DIR     "${PWD}/.."
set SRC_DIR      "${FPGA_DIR}/../src"
set FPGA_RTL_DIR "${FPGA_DIR}/rtl"
set FPGA_XDC_DIR "${FPGA_DIR}/xdc"
set REPORTS_DIR  $::env(REPORT_DIR)

set TOP pq_fpga_top
set CONSTR_FILE ${FPGA_XDC_DIR}/pq_fpga.xdc
set SRC_FILES   " \
  ${FPGA_RTL_DIR}/pq_fpga_pkg.svh \
  ${SRC_DIR}/array_pq/pq_pkg.svh \
  ${SRC_DIR}/array_pq/pq_cell.sv \
  ${SRC_DIR}/array_pq/pq_cell_fsm.sv \
  ${SRC_DIR}/array_pq/pq.sv \
  ${FPGA_RTL_DIR}/pq_fpga_top.sv \
"
# data widths and queue depths
set DATA_WIDTH  [list 8 16 32 64]
set QUEUE_DEPTH [list 32 64 128 256]
# IP instance names
set IP_CLK_WIZ_NAME "i_clk_gen"

# create project
create_project ${PROJECT} ./${PROJECT} -part ${FPGA_PART} -force

# add sources
add_files -norecurse ${SRC_FILES}
add_files -fileset constrs_1 ${CONSTR_FILE}

# generate clock wizard 
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [eval list CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
                              CONFIG.PRIM_IN_FREQ {${FPGA_CLK_FREQ_MHZ}} \
                              CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {${DESIGN_CLK_FREQ_MHZ}} \
                              CONFIG.USE_LOCKED {true} \
                              CONFIG.RESET_TYPE {ACTIVE_LOW} \
                   ] [get_ips clk_wiz_0]
                       
# create OOC netlist
generate_target all [get_ips clk_wiz_0]

update_compile_order -fileset sources_1

# set top and make pq_fpga_pkg globally visible
set_property top ${TOP} [current_fileset]
set_property is_global_include 1 [get_files ${FPGA_RTL_DIR}/pq_fpga_pkg.svh]

# increment through differe Data Width and Queue Depth values, perform synth and write util report
foreach d_width ${DATA_WIDTH} {
  foreach q_depth ${QUEUE_DEPTH} {

    set SYNTH_RUN "syn_dwidth_${d_width}_qdepth_${q_depth}"
    set IMPL_RUN  "impl_dwidth_${d_width}_qdepth_${q_depth}"
    puts "\n\n====================================================================================="
    puts "Running Synthesis for DATE_WIDTH=${d_width} and QUEUE_DEPTH is ${q_depth}"
    puts "SYNTH_RUN name: ${SYNTH_RUN}"
    puts "=====================================================================================\n\n"
    
    # create synthesis run
    create_run ${SYNTH_RUN} -flow "Vivado Synthesis ${VIVADO_VER}" -srcset sources_1 -constrset constrs_1 -part ${FPGA_PART}
    set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs ${SYNTH_RUN}]
    set_property verilog_define "D_WIDTH=${d_width} Q_DEPTH=${q_depth}" [current_fileset]

    # launch synthesis
    launch_runs ${SYNTH_RUN}
    wait_on_run ${SYNTH_RUN}

    # create implementation run
    create_run ${IMPL_RUN} -parent_run ${SYNTH_RUN} -flow "Vivado Implementation ${VIVADO_VER}"

    # launch implementation
    launch_runs ${IMPL_RUN}
    wait_on_run ${IMPL_RUN}

    open_run ${SYNTH_RUN} -name ${SYNTH_RUN}

    report_utilization -hierarchical -hierarchical_percentages -file ${REPORTS_DIR}/${SYNTH_RUN}_util.rpt

    close_design
  }
}

puts "Synthesis Complete. Utilisation reports stored under: ${REPORTS_DIR}."
puts "Goodbye!"


