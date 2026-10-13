# Create Clock 10MHz (Period 100ns)
create_clock -name clk -period 100 [get_ports clk]

# Set I/O Delays
set_input_delay -clock clk 10 [all_inputs]
set_output_delay -clock clk 10 [all_outputs]

# Set Clock Uncertainty
set_clock_uncertainty 0.25 [get_clocks clk]
