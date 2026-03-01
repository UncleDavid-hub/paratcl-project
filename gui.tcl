namespace eval paragui {
    proc init_master {} {
        if {[catch {package require Tk} err]} {
            puts "Tk not available, master cannot run GUI: $err"
            return 0
        }
        wm title . "ParaTcl Master Controller"
        label .l -text "ParaTcl Master Node"
        pack .l
        
        # A listbox to show discovered peers
        label .lp -text "Connected Peers:"
        pack .lp
        listbox .peers -width 40
        pack .peers
        
        # Log area
        label .ll -text "Event Log:"
        pack .ll
        text .log -height 10 -width 50
        pack .log
        
        return 1
    }

    proc log {msg} {
        if {[info exists .log]} {
            .log insert end "$msg\n"
            .log see end
        } else {
            puts "LOG: $msg"
        }
    }

    proc update_peer_list {peers} {
        if {[catch {winfo exists .peers} exists] || !$exists} return
        .peers delete 0 end
        foreach p $peers {
            .peers insert end $p
        }
    }
}

package provide paragui 1.0
