proc build_fsbl {args} {
    set board 0
    for {set i 0} {$i < [llength $args]} {incr i} {
        if {[lindex $args $i] == "-board"} {
            set board [string toupper [lindex $args [expr {$i + 1}]]]
        }
    }
    set design_handoff [glob -nocomplain -directory [pwd] -type f *.xsa *.hdf]
    open_hw_design $design_handoff
    # embeddedsw repo might be included
    if {[file isdirectory embeddedsw]} {
        puts "INFO: Adding embeddedsw repo"
        set_repo_path ./embeddedsw
    }
    # create a software project using templates
    set fsbl_design [create_sw_design fsbl_1 -proc ps7_cortexa9_0 -app zynq_fsbl]
    if {$board != 0} {
        set_property -name APP_COMPILER_FLAGS -value "-DXPS_BOARD_${board}" -objects $fsbl_design
    }
    generate_app -dir zynq_fsbl -compile
    close_hw_design [current_hw_design]
}


# NOTE: This procedure only applies to ZyNQMP!!!!!
proc mp_build_pmufw {} { 
    # Get the hardware design file (xsa or hdf in different versions)
    set design_handoff [glob -nocomplain -directory [pwd] -type f *.xsa *.hdf]
    set hwdsgn [open_hw_design $design_handoff]
    # embeddedsw repo might be included
    if {[file isdirectory embeddedsw]} {
        puts "INFO: Adding embeddedsw repo"
        set_repo_path ./embeddedsw
    }
    generate_app -hw $hwdsgn -os standalone -proc psu_pmu_0 -app zynqmp_pmufw -compile -sw pmufw -dir zynqmp_pmufw
    close_hw_design [current_hw_design]
}

proc build_dts {args} {
    set board 0
    set version 2019.1
    # Get the parameters: board and version
    for {set i 0} {$i < [llength $args]} {incr i} {
        if {[lindex $args $i] == "-board"} {
            set board [string tolower [lindex $args [expr {$i + 1}]]]
        }
        if {[lindex $args $i] == "-version"} {
            set version [string toupper [lindex $args [expr {$i + 1}]]]
        }
    }
    # Get the hardware design file (xsa or hdf in different versions)
    set design_handoff [glob -nocomplain -directory [pwd] -type f *.xsa *.hdf]
    open_hw_design $design_handoff
    set_repo_path ./repo
    # The -proc option is typically one of these values: 
    #     for Versal      "psv_cortexa72_0"
    #     for ZynqMP      "psu_cortexa53_0"
    #     for Zynq-7000   "ps7_cortexa9_0"
    #     for Microblaze  "microblaze_0"
    create_sw_design device-tree -os device_tree -proc ps7_cortexa9_0
    # Generate dts file for the design (SoC only, not include the board hardware)
    generate_target -dir my_dts
    close_hw_design [current_hw_design]
    # If a board is specified, the corresponding dtsi file will be added
    # TODO: Is it optional? 
    if {$board != 0} {
        foreach lib [glob -nocomplain -directory repo/my_dtg/device-tree-xlnx/device_tree/data/kernel_dtsi/${version}/include/dt-bindings -type d *] {
            if {![file exists my_dts/include/dt-bindings/[file tail $lib]]} {
                file copy -force $lib my_dts/include/dt-bindings
            }
        }
        set dtsi_files [glob -nocomplain -directory repo/my_dtg/device-tree-xlnx/device_tree/data/kernel_dtsi/${version}/BOARD -type f *${board}*]
        if {[llength $dtsi_files] != 0} {
            file copy -force [lindex $dtsi_files end] my_dts
            set fileId [open my_dts/system-user.dtsi "w"]
            puts $fileId "/include/ \"[file tail [lindex $dtsi_files end]]\""
            puts $fileId "/ {"
            puts $fileId "};"
            close $fileId
        } else {
            puts "Info: Board file: $board is not found and will not be added to the system-top.dts"
        }
    }
}
