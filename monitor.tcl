package require Tk

namespace eval cluster_monitor {
    variable hosts {}
    variable poll_interval 5000
    variable monitor_running 0

    proc init {host_list} {
        variable hosts
        set hosts $host_list

        if {[llength $hosts] == 0} {
            set hosts {"localhost"}
        }

        build_gui
        start_polling
    }

    proc build_gui {} {
        if {[winfo exists .cluster_monitor]} {
            destroy .cluster_monitor
        }

        toplevel .cluster_monitor
        wm title .cluster_monitor "ParaTcl Cluster Health Monitor"

        set f [frame .cluster_monitor.content -padx 10 -pady 10]
        pack $f -fill both -expand 1

        label $f.title -text "Cluster Health Status" -font {Helvetica 14 bold}
        pack $f.title -pady 5

        set table [frame $f.table]
        pack $table -fill both -expand 1

        label $table.h_host -text "Host" -font {Helvetica 10 bold} -width 15 -anchor w
        label $table.h_temp -text "Temperature" -font {Helvetica 10 bold} -width 15 -anchor c
        label $table.h_throt -text "Status/Throttling" -font {Helvetica 10 bold} -width 20 -anchor c

        grid $table.h_host $table.h_temp $table.h_throt -sticky nsew

        variable hosts
        foreach host $hosts {
            set h_sanitized [string map {. _ : _} $host]
            label $table.host_$h_sanitized -text $host -anchor w
            label $table.temp_$h_sanitized -text "Waiting..." -background "#eeeeee"
            label $table.throt_$h_sanitized -text "Waiting..." -background "#eeeeee"

            grid $table.host_$h_sanitized $table.temp_$h_sanitized $table.throt_$h_sanitized -sticky nsew
        }
    }

    proc start_polling {} {
        variable monitor_running
        set monitor_running 1
        poll_nodes
    }

    proc poll_nodes {} {
        variable hosts
        variable poll_interval
        variable monitor_running

        if {!$monitor_running} return

        foreach host $hosts {
            set h_sanitized [string map {. _ : _} $host]

            if {$host eq "localhost" || $host eq "127.0.0.1"} {
                set temp [get_local_temp]
                set throt [get_local_throttled]
            } else {
                if {[catch {exec ssh -o ConnectTimeout=1 -o BatchMode=yes $host "cat /sys/class/thermal/thermal_zone0/temp; vcgencmd get_throttled"} result]} {
                    set temp "Err"
                    set throt "Unreachable"
                } else {
                    set lines [split $result "\n"]
                    set temp [expr {[lindex $lines 0] / 1000.0}]
                    set throt [lindex $lines 1]
                }
            }

            update_ui $h_sanitized $temp $throt
        }

        after $poll_interval [namespace current]::poll_nodes
    }

    proc get_local_temp {} {
        if {[file exists "/sys/class/thermal/thermal_zone0/temp"]} {
            set fp [open "/sys/class/thermal/thermal_zone0/temp" r]
            set t [read $fp]
            close $fp
            return [expr {$t / 1000.0}]
        }
        return "N/A"
    }

    proc get_local_throttled {} {
        if {[auto_execok vcgencmd] ne ""} {
            return [exec vcgencmd get_throttled]
        }
        return "N/A"
    }

    proc update_ui {host_id temp throt} {
        set color "black"
        if {$temp ne "N/A" && $temp ne "Err" && $temp > 70} { set color "orange" }
        if {$temp ne "N/A" && $temp ne "Err" && $temp > 80} { set color "red" }

        if {[winfo exists .cluster_monitor.content.table.temp_$host_id]} {
            .cluster_monitor.content.table.temp_$host_id configure -text "${temp} C" -foreground $color
            .cluster_monitor.content.table.throt_$host_id configure -text $throt
        }
    }
}

package provide cluster_monitor 1.0
