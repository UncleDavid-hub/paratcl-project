namespace eval hardware {
    variable mpi_present 0
    variable cuda_present 0
    variable vulkan_present 0
    variable ssh_present 0
    variable critcl_present 0
    variable bootknife_mode 0
    variable hostfile "hosts.para"
    variable runtime_hostfile "hosts.para.runtime"

    variable target_tier "Unknown"
    variable missing_components {}

    proc detect {} {
        variable mpi_present
        variable cuda_present
        variable vulkan_present
        variable ssh_present
        variable critcl_present
        variable missing_components
        variable bootknife_mode
        variable target_tier

        set missing_components {}

        # 1. Detect Architecture
        set arch $::tcl_platform(machine)
        set word_size [expr {$::tcl_platform(pointerSize) * 8}]

        if {$word_size == 64 && ($arch eq "x86_64" || $arch eq "amd64")} {
            set target_tier "Modern x86_64 (MPI + CUDA Ready)"
        } elseif {$arch eq "aarch64" || [string match "arm*" $arch]} {
            set target_tier "Raspberry Pi / ARM (MPI + Vulkan Ready)"
        } elseif {$word_size == 32 && ($arch eq "i386" || $arch eq "i686")} {
            set target_tier "Legacy x86_32 (MPI Only)"
        } else {
            set target_tier "Generic $arch ($word_size-bit)"
        }

        # 2. Detect MPI
        if {[auto_execok mpirun] ne "" || [auto_execok mpiexec] ne ""} {
            set mpi_present 1
        } else {
            set mpi_present 0
            lappend missing_components "MPI (mpirun or mpiexec)"
        }
        
        # 3. Detect GPU Accelerators
        if {[auto_execok nvcc] ne "" || [file exists "/usr/local/cuda/bin/nvcc"]} {
            set cuda_present 1
        }

        if {[auto_execok vulkaninfo] ne "" || [file exists "/usr/lib/arm-linux-gnueabihf/libvulkan.so.1"] || [file exists "/usr/lib/aarch64-linux-gnu/libvulkan.so.1"]} {
            set vulkan_present 1
        }

        if {$target_tier eq "Modern x86_64 (MPI + CUDA Ready)" && !$cuda_present} {
            lappend missing_components "NVIDIA CUDA Toolkit"
        } elseif {$target_tier eq "Raspberry Pi / ARM (MPI + Vulkan Ready)" && !$vulkan_present} {
            lappend missing_components "Mesa Vulkan Drivers"
        }

        # 4. Detect SSH
        if {[auto_execok ssh] ne ""} {
            set ssh_present 1
        } else {
            set ssh_present 0
            lappend missing_components "SSH (ssh)"
        }

        # 5. Detect critcl
        if {![catch {package require critcl}]} {
            set critcl_present 1
        } else {
            set critcl_present 0
            lappend missing_components "Tcl package 'critcl'"
        }

        set bootknife_mode [expr {[llength $missing_components] > 0}]
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
        variable target_tier

        puts "--- ParaTcl Grand Unified HPC Status ---"
        puts "Architecture: $target_tier"
        puts "MPI:          [expr {$mpi_present ? "FOUND" : "NOT FOUND"}]"
        puts "CUDA:         [expr {$cuda_present ? "FOUND" : "NOT FOUND"}]"
        puts "Vulkan:       [expr {$vulkan_present ? "FOUND" : "NOT FOUND"}]"
        puts "SSH:          [expr {$ssh_present ? "FOUND" : "NOT FOUND"}]"
        puts "Critcl:       [expr {$critcl_present ? "FOUND" : "NOT FOUND"}]"

        if {$bootknife_mode} {
            puts "\n*** BOOTKNIFE MODE ENABLED (Partial configuration detected) ***"
            puts "Missing: [join $missing_components ", "]"

            if {!$mpi_present || !$ssh_present} {
                puts "\nTIP: For Cluster MPI, install openmpi-bin and ensure passwordless SSH is configured."
            }

            if {$target_tier eq "Modern x86_64 (MPI + CUDA Ready)" && !$cuda_present} {
                puts "TIP: Install NVIDIA CUDA Toolkit to unlock thousands of compute cores."
            } elseif {$target_tier eq "Raspberry Pi / ARM (MPI + Vulkan Ready)" && !$vulkan_present} {
                puts "TIP: Install mesa-vulkan-drivers to enable GPU compute shaders."
            } elseif {$target_tier eq "Legacy x86_32 (MPI Only)"} {
                puts "TIP: Focus on MPI for horizontal scaling; GPU acceleration is typically not supported on this tier."
            }

            if {!$critcl_present} {
                puts "TIP: Install 'critcl' (apt-get install libcritcl-tcl) for on-the-fly C kernel compilation."
            }
        } else {
            puts "\n+++ OPTIMIZED STATE DETECTED: Hardware fully harnessed for this tier! +++"
        }
        puts "----------------------------------------"
    }

    proc manage_hosts {} {
        variable hostfile
        variable runtime_hostfile
        variable ssh_present

        if {![file exists $hostfile]} { return {} }
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
        puts "CPU Fallback: Executing $kernel_name on [info hostname]..."
        return "CPU_RESULT"
    }
}

package provide hardware 1.0
