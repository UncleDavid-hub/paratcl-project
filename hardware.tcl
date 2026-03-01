namespace eval hardware {
    variable mpi_present 0
    variable cuda_present 0

    proc detect {} {
        variable mpi_present
        variable cuda_present
        
        # Detect MPI
        if {[auto_execok mpirun] ne "" || [auto_execok mpiexec] ne ""} {
            set mpi_present 1
        }
        
        # Detect CUDA
        if {[auto_execok nvcc] ne ""} {
            set cuda_present 1
        }
        
        # Check for CUDA via environment or library if nvcc not in path
        if {!$cuda_present} {
            if {[file exists "/usr/local/cuda/bin/nvcc"]} {
                set cuda_present 1
            }
        }
        
        return [list $mpi_present $cuda_present]
    }

    proc status {} {
        variable mpi_present
        variable cuda_present
        puts "Hardware status: MPI=[expr {$mpi_present ? "YES" : "NO"}], CUDA=[expr {$cuda_present ? "YES" : "NO"}]"
    }

    # Parallel command execution with MPI
    proc mpi_run {cmd} {
        variable mpi_present
        if {$mpi_present} {
            puts "Running with MPI (simulated): $cmd"
            # Actual mpirun call would look like this:
            # exec mpirun -n 4 tclsh your_script.tcl {*}$cmd
        } else {
            puts "MPI not found, running locally: $cmd"
            eval $cmd
        }
    }

    # Template for CUDA kernel offloading via critcl (if available)
    proc cuda_offload {code_snippet args} {
        variable cuda_present
        if {!$cuda_present} {
            puts "CUDA hardware not detected, skipping kernel execution."
            return
        }

        if {[catch {package require critcl}]} {
            puts "Critcl not found, cannot compile CUDA kernel."
            return
        }

        # Simulated CUDA integration with critcl
        puts "Compiling and offloading CUDA kernel (simulated): $code_snippet"
        # In a real app, this would use critcl::cproc or similar with nvcc as the compiler
    }
}

package provide hardware 1.0
