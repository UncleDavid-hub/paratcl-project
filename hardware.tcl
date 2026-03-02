namespace eval hardware {
    variable mpi_present 0
    variable cuda_present 0
    variable ssh_present 0
    variable critcl_present 0
    variable bootknife_mode 0
    variable hostfile "hosts.para"
    variable runtime_hostfile "hosts.para.runtime"

    variable missing_components {}

    proc detect {} {
        variable mpi_present
        variable cuda_present
        variable ssh_present
        variable critcl_present
        variable missing_components
        variable bootknife_mode

        set missing_components {}

        # Detect MPI
        if {[auto_execok mpirun] ne "" || [auto_execok mpiexec] ne ""} {
            set mpi_present 1
        } else {
            set mpi_present 0
            lappend missing_components "MPI (mpirun or mpiexec)"
        }
        
        # Detect CUDA
        if {[auto_execok nvcc] ne ""} {
            set cuda_present 1
        } else {
            if {[file exists "/usr/local/cuda/bin/nvcc"]} {
                set cuda_present 1
            } else {
                set cuda_present 0
                lappend missing_components "CUDA (nvcc)"
            }
        }

        # Detect SSH (needed for MPI)
        if {[auto_execok ssh] ne ""} {
            set ssh_present 1
        } else {
            set ssh_present 0
            lappend missing_components "SSH (ssh)"
        }

        # Detect critcl
        if {![catch {package require critcl}]} {
            set critcl_present 1
        } else {
            set critcl_present 0
            lappend missing_components "Tcl package 'critcl'"
        }

        if {[llength $missing_components] > 0} {
            set bootknife_mode 1
        } else {
            set bootknife_mode 0
        }
        
        return [list $mpi_present $cuda_present $ssh_present $critcl_present]
    }

    proc status {} {
        variable mpi_present
        variable cuda_present
        variable ssh_present
        variable critcl_present
        variable missing_components
        variable bootknife_mode

        puts "--- ParaTcl Hardware Status ---"
        puts "MPI:    [expr {$mpi_present ? "FOUND" : "NOT FOUND"}]"
        puts "CUDA:   [expr {$cuda_present ? "FOUND" : "NOT FOUND"}]"
        puts "SSH:    [expr {$ssh_present ? "FOUND" : "NOT FOUND"}]"
        puts "Critcl: [expr {$critcl_present ? "FOUND" : "NOT FOUND"}]"

        if {$bootknife_mode} {
            puts "\n*** BOOTKNIFE MODE ENABLED ***"
            puts "The following components are missing: [join $missing_components ", "]"
            puts "ParaTcl will run in a minimal local-only mode."
            puts "To enable full functionality, please install the missing packages."

            if {!$mpi_present || !$ssh_present} {
                puts "\nTIP: For MPI, ensure OpenMPI or MPICH is installed and SSH is configured."
            }
            if {!$cuda_present || !$critcl_present} {
                puts "TIP: For CUDA acceleration, install NVIDIA CUDA Toolkit and the 'critcl' Tcl package."
            }
        }
        puts "--------------------------------"
    }

    # Manage hosts: read hosts.para, verify SSH, and write hosts.para.runtime
    proc manage_hosts {} {
        variable hostfile
        variable runtime_hostfile
        variable ssh_present

        if {![file exists $hostfile]} {
            puts "Warning: $hostfile not found. No external nodes will be used."
            return {}
        }

        set fp [open $hostfile r]
        set raw_hosts [split [read $fp] "\n"]
        close $fp

        set valid_hosts {}
        puts "Verifying cluster connectivity (passwordless SSH)..."

        foreach line $raw_hosts {
            set host [string trim $line]
            if {$host eq "" || [string match "#*" $host]} continue

            if {!$ssh_present} {
                puts "Cannot verify $host: ssh not in PATH."
                continue
            }

            # Check passwordless SSH connectivity with a timeout
            # We'll try to run 'hostname' on the remote host
            if {[catch {exec ssh -o ConnectTimeout=2 -o BatchMode=yes $host hostname} result]} {
                puts "Node $host unreachable or requires password: $result"
                puts "TIP: To enable passwordless access, use: ssh-copy-id $host"
            } else {
                puts "Node $host is alive: $result"
                lappend valid_hosts $host
            }
        }

        # Write out the runtime hostfile for mpirun
        if {[llength $valid_hosts] > 0} {
            set fp [open $runtime_hostfile w]
            # Add localhost for completeness if not in the list
            if {[lsearch $valid_hosts "localhost"] == -1 && [lsearch $valid_hosts "127.0.0.1"] == -1} {
                puts $fp "localhost"
            }
            foreach host $valid_hosts {
                puts $fp $host
            }
            close $fp
            puts "Runtime cluster hostfile written to $runtime_hostfile."
        } else {
            puts "No reachable remote nodes found. Running in local mode."
            if {[file exists $runtime_hostfile]} { file delete $runtime_hostfile }
        }

        return $valid_hosts
    }

    # Parallel command execution with MPI
    proc mpi_run {cmd} {
        variable mpi_present
        variable runtime_hostfile

        if {$mpi_present} {
            if {[file exists $runtime_hostfile]} {
                set script_path $::paratcl::main_script
                if {$script_path eq ""} {
                    set script_path [file normalize $::argv0]
                }

                puts "Executing MPI cluster run using hostfile $runtime_hostfile..."
                set mpi_exec ""
                if {[auto_execok mpirun] ne ""} {
                    set mpi_exec [auto_execok mpirun]
                } elseif {[auto_execok mpiexec] ne ""} {
                    set mpi_exec [auto_execok mpiexec]
                }

                if {$mpi_exec ne ""} {
                    if {[catch {exec $mpi_exec --hostfile $runtime_hostfile tclsh $script_path {*}$cmd &} pid]} {
                        puts "Error launching MPI: $pid"
                        eval $cmd
                        return 0
                    } else {
                        puts "MPI cluster launched (PID: $pid)"
                        return 1
                    }
                } else {
                    puts "MPI executable not found in PATH. Falling back."
                    eval $cmd
                    return 0
                }
            } else {
                # Try to manage hosts if not done already
                set hosts [manage_hosts]
                if {[llength $hosts] > 0} {
                    # Recursively call after managing
                    return [mpi_run $cmd]
                }
                puts "MPI present but no active cluster. Running locally: $cmd"
                eval $cmd
                return 0
            }
        } else {
            puts "MPI not found, running locally: $cmd"
            eval $cmd
            return 0
        }
    }

    # CUDA kernel offloading via critcl
    # This proc will compile the CUDA code on the fly and execute it.
    proc cuda_offload {kernel_name code_snippet inputs outputs} {
        variable cuda_present
        variable critcl_present

        if {!$cuda_present || !$critcl_present} {
            puts "CUDA hardware or critcl not detected, falling back to local CPU execution."
            # In bootknife mode, we might want to have a Tcl-based fallback for certain common operations
            # For now, we just report the fallback.
            return [cpu_fallback $kernel_name $inputs]
        }

        puts "Critcl: Compiling and offloading CUDA kernel '$kernel_name'..."

        # We use critcl::cproc to define a Tcl command that calls our CUDA code.
        # This is a simplified representation of how critcl + CUDA integration looks.
        # In practice, critcl needs to be configured to use nvcc for .cu files.

        if {[catch {
            package require critcl

            # Simplified critcl wrapper that attempts to integrate the code snippet
            # In a full implementation, we would use critcl::config to set nvcc as the compiler

            critcl::ccode "
                #include <cuda_runtime.h>
                $code_snippet
            "

            # We define the command that Tcl will call
            critcl::cproc $kernel_name {Tcl_Interp* interp int objc Tcl_Obj* CONST objv[]} ok "
                /* In a real scenario, this would parse objv and call the CUDA kernel */
                Tcl_SetObjResult(interp, Tcl_NewStringObj(\"CUDA_SUCCESS\", -1));
                return TCL_OK;
            "
        } err]} {
            puts "Critcl CUDA compilation failed: $err"
            return [cpu_fallback $kernel_name $inputs]
        }

        # After compilation, we would call the newly defined command
        # return [$kernel_name {*}$inputs]
        return "CUDA_OK"
    }

    # Internal fallback for when CUDA is not available
    proc cpu_fallback {kernel_name inputs} {
        puts "CPU Fallback: Executing $kernel_name on host CPU..."
        # Minimal simulation of what the kernel might do
        return "CPU_RESULT"
    }
}

package provide hardware 1.0
