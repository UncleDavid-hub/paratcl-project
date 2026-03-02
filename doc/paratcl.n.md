# NAME
paratcl - ParaTcl main initialization and control module

# SYNOPSIS
```tcl
paratcl::init master_flag ?discovery_port?
```

# DESCRIPTION
The `paratcl` module is the primary entry point for ParaTcl applications. It orchestrates the initialization of all sub-modules and manages the automatic deployment of the cluster via MPI if available.

# COMMANDS
**paratcl::init** *master_flag* ?*discovery_port*?
Initializes the ParaTcl node. 
- *master_flag*: Boolean. If 1, the node starts as a MASTER.
- *discovery_port*: Optional. The UDP port for node discovery (defaults to 9999).

On a Master node, `init` will:
1. Initialize the secured communication layer.
2. Detect hardware capabilities.
3. If MPI is available and the process hasn't been spawned yet, it will use `hardware::mpi_run` to deploy the script across the cluster and then the initial process will exit.
4. Start the discovery broadcaster and listener.
5. Launch the ParaGUI if Tk is available.

# VARIABLES
**paratcl::main_script**
Stores the normalized path to the entry script, used by MPI to ensure all nodes run the same code.

# SEE ALSO
paracomms(n), paravar(n), discovery(n), hardware(n), bootknife(7)
