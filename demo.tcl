# ParaTcl Demo Script
source paratcl.tcl

# Argument processing for master/worker selection
set is_master 0
if {[llength $argv] > 0 && [lindex $argv 0] eq "master"} {
    set is_master 1
}

# Run the ParaTcl initialization
::paratcl::init $is_master

# Define a parallel variable
::paravar::define my_global_var "initial value"

# Demo behavior
if {$is_master} {
    puts "Master node: watch for my_global_var updates from workers."
    
    # Periodically print the variable's value
    proc check_var {} {
        global my_global_var
        puts "Master's view of my_global_var: $my_global_var"
        after 5000 check_var
    }
    check_var
} else {
    puts "Worker node: will update my_global_var shortly."
    
    # Periodically update the parallel variable
    proc update_var_randomly {node_id} {
        global my_global_var
        set new_val "Updated by $node_id at [clock seconds]"
        puts "Worker $node_id updating my_global_var to: $new_val"
        set my_global_var $new_val
        
        # Also send a message to the master GUI
        ::paraworker::update_gui "Worker $node_id changed variable!"
        
        after 10000 [list update_var_randomly $node_id]
    }
    
    # Use comm id as node identifier
    set my_id [::paracomms::init]
    after 5000 [list update_var_randomly $my_id]
}

# Enter the Tcl event loop
vwait forever
