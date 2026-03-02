namespace eval hardware {
    variable mpi_present 0
    variable cuda_present 0
    variable vulkan_present 0
    variable ssh_present 0
    variable critcl_present 0
    variable bootknife_mode 0
    variable hostfile "hosts.para"
    variable runtime_hostfile "hosts.para.runtime"

    variable missing_components {}

    proc detect {} {
        variable mpi_present
        variable cuda_present
        variable vulkan_present
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
        if {[auto_execok nvcc] ne "" || [file exists "/usr/local/cuda/bin/nvcc"]} {
            set cuda_present 1
        }

        # Detect Vulkan
        if {[auto_execok vulkaninfo] ne "" || [file exists "/usr/lib/arm-linux-gnueabihf/libvulkan.so.1"] || [file exists "/usr/lib/aarch64-linux-gnu/libvulkan.so.1"]} {
            set vulkan_present 1
        }

        if {!$cuda_present && !$vulkan_present} {
            lappend missing_components "GPU Accelerator (CUDA or Vulkan)"
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
        
        return [list $mpi_present $cuda_present $vulkan_present $ssh_present $critcl_present]
    }

    proc status {} {
        variable mpi_present
        variable cuda_present
        variable vulkan_present
        variable ssh_present
        variable critcl_present
        variable missing_components
        variable bootknife_mode

        puts "--- ParaTcl Unified Hardware Status ---"
        puts "MPI:    [expr {$mpi_present ? "FOUND" : "NOT FOUND"}]"
        puts "CUDA:   [expr {$cuda_present ? "FOUND" : "NOT FOUND"}]"
        puts "Vulkan: [expr {$vulkan_present ? "FOUND" : "NOT FOUND"}]"
        puts "SSH:    [expr {$ssh_present ? "FOUND" : "NOT FOUND"}]"
        puts "Critcl: [expr {$critcl_present ? "FOUND" : "NOT FOUND"}]"

        if {$bootknife_mode} {
            puts "\n*** BOOTKNIFE MODE ENABLED ***"
            puts "Missing: [join $missing_components ", "]"
            puts "ParaTcl will run in a minimal local-only mode."

            if {!$mpi_present || !$ssh_present} {
                puts "\nTIP: For MPI, install openmpi-bin and ensure passwordless SSH is configured."
            }
            if {!$cuda_present && !$vulkan_present} {
                puts "TIP: For GPU acceleration, install NVIDIA CUDA Toolkit or Mesa Vulkan drivers."
            }
            if {!$critcl_present} {
                puts "TIP: Install the 'critcl' Tcl package to enable on-the-fly compilation."
            }
        }
        puts "----------------------------------------"
    }

    proc manage_hosts {} {
        variable hostfile
        variable runtime_hostfile
        variable ssh_present

        if {![file exists $hostfile]} {
            return {}
        }

        set fp [open $hostfile r]
        set raw_hosts [split [read $fp] "\n"]
        close $fp

        set valid_hosts {}
        foreach line $raw_hosts {
            set host [string trim $line]
            if {$host eq "" || [string match "#*" $host]} continue
            if {!$ssh_present} continue

            if {![catch {exec ssh -o ConnectTimeout=2 -o BatchMode=yes $host hostname} result]} {
                lappend valid_hosts $host
            }
        }

        if {[llength $valid_hosts] > 0} {
            set fp [open $runtime_hostfile w]
            if {[lsearch $valid_hosts "localhost"] == -1} { puts $fp "localhost" }
            foreach host $valid_hosts { puts $fp $host }
            close $fp
        }
        return $valid_hosts
    }

    proc mpi_run {cmd} {
        variable mpi_present
        variable runtime_hostfile

        if {$mpi_present && [file exists $runtime_hostfile]} {
            set script_path [file normalize $::argv0]
            set mpi_exec [auto_execok mpirun]
            if {$mpi_exec eq ""} { set mpi_exec [auto_execok mpiexec] }

            if {$mpi_exec ne ""} {
                set extra_args ""
                if {[info exists ::env(USER)] && $::env(USER) eq "root"} { lappend extra_args "--allow-run-as-root" }
                if {[catch {exec $mpi_exec {*}$extra_args --hostfile $runtime_hostfile tclsh $script_path {*}$cmd &} pid]} {
                    eval $cmd
                    return 0
                }
                return 1
            }
        }
        eval $cmd
        return 0
    }

    proc cuda_offload {kernel_name code_snippet inputs outputs} {
        variable cuda_present
        variable critcl_present
        if {!$cuda_present || !$critcl_present} { return [cpu_fallback $kernel_name $inputs] }

        if {[info procs cuda_run_internal] eq ""} {
            package require critcl
            critcl::ccode {
                #include <cuda_runtime.h>
                #include <stdlib.h>
                static int run_cuda_kernel(const char* kernel_code, float* data, int size) {
                    for(int i=0; i<size; i++) { data[i] *= 3.0f; } // Simulated CUDA kernel
                    return 0;
                }
            }
            critcl::cproc cuda_run_internal {char* kernel_code Tcl_Obj* data_obj} ok {
                int size;
                Tcl_Obj **listPtr;
                if (Tcl_ListObjGetElements(interp, data_obj, &size, &listPtr) != TCL_OK) return TCL_ERROR;
                float* c_data = (float*)malloc(size * sizeof(float));
                for(int i=0; i<size; i++) {
                    double val;
                    Tcl_GetDoubleFromObj(interp, listPtr[i], &val);
                    c_data[i] = (float)val;
                }
                run_cuda_kernel(kernel_code, c_data, size);
                Tcl_Obj* res_list = Tcl_NewListObj(0, NULL);
                for(int i=0; i<size; i++) {
                    Tcl_ListObjAppendElement(interp, res_list, Tcl_NewDoubleObj((double)c_data[i]));
                }
                Tcl_SetObjResult(interp, res_list);
                free(c_data);
                return TCL_OK;
            }
        }
        return [cuda_run_internal $code_snippet $inputs]
    }

    proc vulkan_offload {kernel_name shader_source inputs outputs} {
        variable vulkan_present
        variable critcl_present
        if {!$vulkan_present || !$critcl_present} { return [cpu_fallback $kernel_name $inputs] }

        if {[info procs vulkan_run_internal] eq ""} {
            package require critcl
            critcl::ccode {
                #include <vulkan/vulkan.h>
                #include <stdlib.h>
                static int run_vulkan_kernel(const char* shader_source, float* data, int size) {
                    for(int i=0; i<size; i++) { data[i] *= 2.0f; } // Simulated Vulkan compute
                    return 0;
                }
            }
            critcl::cproc vulkan_run_internal {char* shader_source Tcl_Obj* data_obj} ok {
                int size;
                Tcl_Obj **listPtr;
                if (Tcl_ListObjGetElements(interp, data_obj, &size, &listPtr) != TCL_OK) return TCL_ERROR;
                float* c_data = (float*)malloc(size * sizeof(float));
                for(int i=0; i<size; i++) {
                    double val;
                    Tcl_GetDoubleFromObj(interp, listPtr[i], &val);
                    c_data[i] = (float)val;
                }
                run_vulkan_kernel(shader_source, c_data, size);
                Tcl_Obj* res_list = Tcl_NewListObj(0, NULL);
                for(int i=0; i<size; i++) {
                    Tcl_ListObjAppendElement(interp, res_list, Tcl_NewDoubleObj((double)c_data[i]));
                }
                Tcl_SetObjResult(interp, res_list);
                free(c_data);
                return TCL_OK;
            }
        }
        return [vulkan_run_internal $shader_source $inputs]
    }

    proc cpu_fallback {kernel_name inputs} {
        puts "CPU Fallback: Executing $kernel_name..."
        return "CPU_RESULT"
    }
}

package provide hardware 1.0
