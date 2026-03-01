package require udp

namespace eval discovery {
    variable discovery_port 9999
    variable peers {}
    variable my_comm_port 0
    variable udp_sock

    proc init {comm_port {dport 9999}} {
        variable discovery_port
        variable my_comm_port
        variable udp_sock
        set my_comm_port $comm_port
        set discovery_port $dport

        # Open UDP socket for listening with reuse to allow multiple instances on same host
        if {[catch {udp_open $discovery_port -reuse} udp_sock]} {
            puts "Warning: Could not bind to discovery port $discovery_port: $udp_sock"
            return
        }
        fconfigure $udp_sock -buffering none -translation binary -broadcast 1
        fileevent $udp_sock readable [list [namespace current]::receive_handler $udp_sock]
        
        puts "Discovery listening on $discovery_port, advertising comm port $my_comm_port"
        
        # Start broadcasting
        broadcast
    }

    proc receive_handler {sock} {
        variable peers
        variable my_comm_port
        set data [read $sock]
        set peer_info [chan configure $sock -peer]
        set peer_ip [lindex $peer_info 0]
        
        if {[scan $data "HELLO %d" remote_comm_port] == 1} {
            # Don't add ourselves
            set peer_key $remote_comm_port
            
            if {[lsearch $peers $peer_key] == -1} {
                if {$remote_comm_port == $my_comm_port} {
                    return
                }
                
                puts "Discovered new peer: $peer_key"
                lappend peers $peer_key
            }
        }
    }

    proc broadcast {} {
        variable discovery_port
        variable my_comm_port
        
        set msg "HELLO $my_comm_port"
        
        if {[catch {
            set s [udp_open]
            fconfigure $s -broadcast 1
            
            # Send to localhost explicitly for local demo reliability
            chan configure $s -remote [list 127.0.0.1 $discovery_port]
            puts -nonewline $s $msg
            flush $s
            
            # Broadcast to the subnet. 255.255.255.255 is universal.
            # Some systems prefer 127.255.255.255 for localhost broadcast
            catch {
                chan configure $s -remote [list 127.255.255.255 $discovery_port]
                puts -nonewline $s $msg
                flush $s
            }
            
            catch {
                # Also try 255.255.255.255
                chan configure $s -remote [list 255.255.255.255 $discovery_port]
                puts -nonewline $s $msg
                flush $s
            }
            close $s
        } err]} {
            # puts "Broadcast error: $err"
        }
        
        # Broadcast every 5 seconds
        after 5000 [namespace current]::broadcast
    }
    
    proc get_peers {} {
        variable peers
        return $peers
    }
}

package provide discovery 1.0
