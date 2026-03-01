# NAME
paravar - ParaTcl parallel variable synchronization module

# SYNOPSIS
```tcl
paravar::define varname ?initial_value?
paravar::update_peers peers
```

# DESCRIPTION
The `paravar` module provides a way to define variables that are automatically kept in sync across all nodes in the ParaTcl cluster. It uses variable traces to detect changes and broadcasts updates to peers.

# COMMANDS
**paravar::define** *varname* ?*initial_value*?
Defines a variable in the caller's scope as a parallel variable. 
- *varname*: The name of the variable (will be fully qualified internally).
- *initial_value*: Optional. The value to initialize the variable with.

**paravar::update_peers** *peers*
Updates the internal list of peers that will receive variable updates. Usually called automatically by the `paratcl` module.

**paravar::remote_update** *fq_varname* *value*
Internal command called by remote nodes to update a local parallel variable.

# EXAMPLES
```tcl
set my_shared_data "init"
paravar::define my_shared_data

# Any subsequent change will be broadcasted:
set my_shared_data "new value"
```

# SEE ALSO
paratcl(n), paracomms(n)
