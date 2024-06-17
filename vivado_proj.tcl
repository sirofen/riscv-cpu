# Set the project name and part
set proj_name "riscv-cpu"
set part_name "xc7k325tffg676-2"

# Check if project already exists
if {[file exists ./proj/$proj_name.xpr]} {
    open_project ./proj/$proj_name.xpr

    reset_run synth_1
} else {
    # Create a new project
    create_project $proj_name ./proj -part $part_name

    # Add directories for source files and constraints
    set src_dir "./rtl"
    set constr_dir "./constraints"
    set ip_dir "./ip"

    # Recursive file search
    add_files -scan_for_includes [glob $src_dir *.sv]

    # Add constraint files
    foreach file [glob $constr_dir/*.xdc] {
        add_files -fileset constrs_1 $file
    }

    # Add the custom IP directory to the IP repository path
    set_property ip_repo_paths $ip_dir [current_project]
    update_ip_catalog

    # Create and configure the Clock Wizard IP
    create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_1
    set_property -dict [list \
        CONFIG.CLKIN1_JITTER_PS {200.0} \
        CONFIG.CLKOUT1_JITTER {162.035} \
        CONFIG.CLKOUT1_PHASE_ERROR {164.985} \
        CONFIG.CLKOUT2_JITTER {192.113} \
        CONFIG.CLKOUT2_PHASE_ERROR {164.985} \
        CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50} \
        CONFIG.CLKOUT2_USED {true} \
        CONFIG.MMCM_CLKFBOUT_MULT_F {20.000} \
        CONFIG.MMCM_CLKIN1_PERIOD {20.000} \
        CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
        CONFIG.MMCM_CLKOUT1_DIVIDE {20} \
        CONFIG.NUM_OUT_CLKS {2} \
        CONFIG.PRIM_IN_FREQ {50} \
        CONFIG.RESET_PORT {resetn} \
        CONFIG.RESET_TYPE {ACTIVE_LOW} \
        CONFIG.USE_LOCKED {false} \
    ] [get_ips clk_wiz_1]

    # Generate the output products for the Clock Wizard
    generate_target {instantiation_template synthesis} [get_files -of_objects [get_ips clk_wiz_1]]
    update_compile_order -fileset sources_1

    # Source the custom DDR3 interface TCL script
    source $ip_dir/ddr3_interface.tcl
    set bd_name ddr3_interface
    generate_target all [get_files ./proj/$proj_name.srcs/sources_1/bd/$bd_name/$bd_name.bd]

    # Generate the output products for the custom DDR3 interface IP
    update_compile_order -fileset sources_1
}

# Synthesize, implement, and generate bitstream
launch_runs synth_1
wait_on_run synth_1
launch_runs impl_1
wait_on_run impl_1
open_run impl_1
write_bitstream [get_property DIRECTORY [current_project]]/top.bit -force

# Close the project
close_project
