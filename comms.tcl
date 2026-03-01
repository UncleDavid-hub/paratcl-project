package require comm

namespace eval paracomms {
    variable comm_id 0
    variable slave_interp

    proc init {} {
        variable comm_id
        variable slave_interp
        
        # Create a restricted slave interpreter
        if {![interp exists slave]} {
            set slave_interp [interp create -safe slave]
        } else {
            set slave_interp slave
        }
        
        # Expose only the necessary ParaTcl commands to the slave
        # These are what remote nodes are allowed to call
        interp alias $slave_interp ::paravar::remote_update {} ::paravar::remote_update
        interp alias $slave_interp ::paragui::log {} ::paragui::log
        interp alias $slave_interp ::paravar::update_peers {} ::paravar::update_peers
        
        # Configure comm to use the slave interpreter for all incoming commands
        ::comm::comm config -interp $slave_interp
        
        set comm_id [::comm::comm self]
        puts "Communication node ID: $comm_id (Secured with Slave Interp)"
        return $comm_id
    }

    proc send_command {peer cmd} {
        # Remote execution of command on peer
        if {[catch {::comm::comm send $peer $cmd} result]} {
            puts "Error sending command to $peer: $result"
            return ""
        }
        return $result
    }

    proc broadcast_command {peers cmd} {
        foreach peer $peers {
            send_command $peer $cmd
        }
    }
}

package provide paracomms 1.0
