# scripts/sim.tcl
# TCL script for Vivado xsim batch mode

# Create a VCD file for waveform analysis
open_vcd waveform.vcd

# Log all signals in the design recursively
log_vcd [get_objects -r *]

# Run the simulation until $finish or timeout
run all

# Close VCD and exit
close_vcd
exit
