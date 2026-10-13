# Read liberty timing library for Sky130
read_liberty /home/trinhnamphong/OpenLane/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Read synthesized netlist from Yosys
read_verilog synth/sat_accumulator_netlist.v

# Link design
link_design sat_accumulator

# Read SDC constraints
read_sdc sta/constraint.sdc

# Report Timing
report_checks -path_delay max -fields {slew cap input net fanout} -digits 4
report_checks -path_delay min -fields {slew cap input net fanout} -digits 4
report_worst_slack -max
report_worst_slack -min
