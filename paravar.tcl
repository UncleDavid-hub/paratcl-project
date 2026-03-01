namespace eval paravar {
    variable sync_peers {}
    variable local_vars {}
    variable syncing 0

    proc init {peers} {
        variable sync_peers
        set sync_peers $peers
    }

    # define accepts a variable name in the caller's scope
    proc define {varname {initial_value ""}} {
        variable local_vars
        
        # Link to the variable in the caller's scope
        upvar 1 $varname v
        
        # Determine the fully qualified name of the variable
        set fq_varname [uplevel 1 [list namespace which -variable $varname]]
        if {$fq_varname eq ""} {
            # If not already fully qualified, assume it's in the current namespace of the caller
            set ns [uplevel 1 {namespace current}]
            if {$ns eq "::"} {
                set fq_varname "::$varname"
            } else {
                set fq_varname "${ns}::$varname"
            }
        }
        
        set v $initial_value
        lappend local_vars $fq_varname
        
        # Add trace to synchronize when the variable is modified
        # The trace is attached to the actual variable in its home scope
        trace add variable v write [list [namespace current]::sync_handler $fq_varname]
        
        puts "Defined parallel variable: $fq_varname"
    }

    proc sync_handler {fq_varname name1 name2 op} {
        variable syncing
        variable sync_peers
        if {$syncing} return

        # Access the value of the fully qualified variable
        set val [set $fq_varname]
        
        # Prevent infinite loops
        set syncing 1
        
        # Sync to all discovered peers
        foreach peer $sync_peers {
            if {[info procs ::paracomms::send_command] ne ""} {
                ::paracomms::send_command $peer [list ::paravar::remote_update $fq_varname $val]
            }
        }
        
        set syncing 0
    }

    proc remote_update {fq_varname value} {
        variable syncing
        variable local_vars
        
        # Only update if we know about this parallel variable
        if {[lsearch $local_vars $fq_varname] != -1} {
            set syncing 1
            set $fq_varname $value
            set syncing 0
        }
    }
    
    proc update_peers {peers} {
        variable sync_peers
        set sync_peers $peers
        # puts "Parallel variable peers updated: $sync_peers"
    }
}

package provide paravar 1.0
