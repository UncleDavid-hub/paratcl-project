namespace eval paraworker {
    variable master_peer ""

    proc set_master {peer} {
        variable master_peer
        set master_peer $peer
        puts "Master set to $master_peer"
    }

    proc update_gui {msg} {
        variable master_peer
        if {$master_peer eq ""} {
            puts "No master set, local message: $msg"
            return
        }
        
        # Call paragui::log on master node
        ::paracomms::send_command $master_peer [list ::paragui::log $msg]
    }
}

package provide paraworker 1.0
