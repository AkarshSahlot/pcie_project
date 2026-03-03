# Vivado 2023.2 Build Script for Alveo U50
# Automatically generated build script for pcie-p4 project

# 1. Project Creation
set project_name "pcie_p4_project"
set project_dir "vivado_project"
set part_name "xcu50-fsvh2104-2-e"
set output_dir "outputs"

file delete -force $project_dir
file mkdir $output_dir

create_project $project_name $project_dir -part $part_name
set_property board_part xilinx.com:u50:part0:1.3 [current_project]

# 2. Add Source Files
add_files -norecurse hdl_src/pcie_p4_wrapper.sv
# Note: main.p4 will be added directly to the Vitis Networking P4 IP configuration

# 3. Create Block Design
create_bd_design "design_1"

# Instantiate PCIe UltraScale+ IP
set pcie_ip [create_bd_cell -type ip -vlnv xilinx.com:ip:pcie4_uscale_plus:1.3 pcie4_uscale_plus_0]

# 4. Configure PCIe IP to bypass standard NIC enumeration (Class Code: 0xFF0000)
set_property -dict [list 
    CONFIG.pf0_class_code {0xFF0000} 
    CONFIG.pf0_base_class_menu {Unassigned_class} 
    CONFIG.pf0_sub_class_interface_menu {Generic_unassigned_device} 
    CONFIG.mode_selection {Advanced} 
    CONFIG.en_gt_selection {true} 
] $pcie_ip

# Instantiate Vitis Networking P4 IP
# Note: Vitis Networking P4 IP (vitis_net_p4) requires the P4 source file path.
set p4_ip [create_bd_cell -type ip -vlnv xilinx.com:ip:vitis_net_p4:1.1 vitis_net_p4_0]

# Configure P4 IP with our source file
set p4_source_path [file normalize "p4_src/main.p4"]
set_property -dict [list 
    CONFIG.P4_FILE $p4_source_path 
    CONFIG.TDATA_NUM_BYTES {32} 
    CONFIG.AXI4_STREAM_DATA_WIDTH {256} 
] $p4_ip

# Connect AXI-Stream interfaces (Simplified representation)
# In a real BD, you would use 'connect_bd_intf_net' for AXIS interfaces.
# CQ (Completer Request) -> P4 Input
connect_bd_intf_net [get_bd_intf_pins pcie4_uscale_plus_0/m_axis_cq] [get_bd_intf_pins vitis_net_p4_0/s_axis]
# P4 Output -> RQ (Requester Request)
connect_bd_intf_net [get_bd_intf_pins vitis_net_p4_0/m_axis] [get_bd_intf_pins pcie4_uscale_plus_0/s_axis_rq]

# Note: Additional clock/reset connections and external ports would be needed here.
# For simplicity, we assume the wrapper logic handles the top-level orchestration.

# Validate and Save BD
validate_bd_design
save_bd_design

# Create HDL Wrapper for BD
make_wrapper -files [get_files $project_dir/$project_name.srcs/sources_1/bd/design_1/design_1.bd] -top
add_files -norecurse $project_dir/$project_name.gen/sources_1/bd/design_1/hdl/design_1_wrapper.v
update_compile_order -fileset sources_1

# 5. Launch Synthesis, Implementation, and Write Bitstream
launch_runs synth_1 -jobs 8
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# Copy final bitstream to output directory
file copy -force $project_dir/$project_name.runs/impl_1/design_1_wrapper.bit $output_dir/design.bit

puts "Build Complete: Outputs saved to $output_dir/design.bit"
