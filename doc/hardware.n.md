# NAME
hardware - ParaTcl hardware detection and acceleration module

# SYNOPSIS
```tcl
hardware::detect
hardware::status
hardware::mpi_run cmd
hardware::cuda_offload code_snippet ?args?
```

# DESCRIPTION
The `hardware` module is responsible for detecting high-performance computing resources such as MPI (Message Passing Interface) and CUDA (NVIDIA GPU acceleration).

# COMMANDS
**hardware::detect**
Scans the environment for `mpirun`, `mpiexec`, and `nvcc`. Returns a list containing two booleans: {mpi_present cuda_present}.

**hardware::status**
Prints a human-readable summary of detected hardware to standard output.

**hardware::mpi_run** *cmd*
Executes the given command using MPI if available. Falls back to local execution otherwise.

**hardware::cuda_offload** *code_snippet* ?*args*?
A framework for offloading computation to a GPU. Requires `critcl` and CUDA drivers. (Currently implements a template for integration).

# SEE ALSO
paratcl(n)
