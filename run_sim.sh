#!/bin/bash
# run_sim.sh
# Bash script to automate Vivado simulation from the command line

set -e # Exit on error

# Step 1: Compile SystemVerilog files
echo "--- Compiling SystemVerilog Sources ---"
xvlog -sv hdl_src/pcie_p4_wrapper.sv hdl_src/tb_pcie_p4_wrapper.sv

# Step 2: Elaborate the design and create a snapshot
echo "--- Elaborating Design (Snapshot: tb_snap) ---"
xelab -debug typical -top tb_pcie_p4_wrapper -snapshot tb_snap

# Step 3: Run the simulation in batch mode
echo "--- Running Simulation (Batch Mode) ---"
xsim tb_snap -tclbatch scripts/sim.tcl

# Final cleanup (optional)
# rm -rf xsim.dir xvlog.log xelab.log xsim.log xvlog.pb xelab.pb
echo "--- Simulation Complete. Waveform saved to waveform.vcd ---"
