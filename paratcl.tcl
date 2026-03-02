# ParaTcl Main Entry Point

source discovery.tcl
source comms.tcl
source paravar.tcl
source hardware.tcl
source gui.tcl
source worker.tcl
source monitor.tcl

namespace eval paratcl {
    variable is_master 0
    variable discovery_port 9999
    variable main_script ""
    variable show_monitor 1

    proc init {master_flag {dport 9999}} {
        variable is_master
        variable discovery_port
        variable show_monitor
        set is_master $master_flag
        set discovery_port $dport

        # Initialize communications
        set comm_id [::paracomms::init]
        
        # Detect hardware
        ::hardware::detect
        ::hardware::status

        # If we have MPI, we can use it to spawn ourselves across the cluster
        if {$is_master && ![info exists ::env(PARA_SPAWNED)]} {
            set ::env(PARA_SPAWNED) 1

            # Identify the main script to run across the cluster
            variable main_script
            if {[info exists ::argv0]} {
                set main_script [file normalize $::argv0]
            } else {
                set main_script [file normalize [info script]]
            }

            # mpi_run will automatically check for hosts.para and connectivity
            if {[::hardware::mpi_run [list]]} {
                puts "Cluster launched. Master process exiting to avoid duplication."
                exit 0
            }
        }
        
        # Initialize discovery
        ::discovery::init $comm_id $discovery_port
        
        if {$is_master} {
            puts "Starting as MASTER"
            ::paragui::init_master

            # Optional Cluster Health Monitor
            if {$show_monitor} {
                set hosts [::hardware::manage_hosts]
                ::cluster_monitor::init $hosts
            }
        } else {
            puts "Starting as WORKER"
        }
        
        # Polling for new peers and updating parallel variables
        update_peers_loop
    }

    proc update_peers_loop {} {
        variable is_master
        set peers [::discovery::get_peers]
        
        if {[llength $peers] > 0} {
            ::paravar::update_peers $peers
            
            if {$is_master} {
                ::paragui::update_peer_list $peers
            }
        }
        
        if {!$is_master && [llength $peers] > 0} {
            set master_peer [lindex $peers 0]
            ::paraworker::set_master $master_peer
        }
        
        after 2000 [namespace current]::update_peers_loop
    }
}
