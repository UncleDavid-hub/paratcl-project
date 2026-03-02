# NAME
paravar - Distributed parallel variables for ParaTcl

# SYNOPSIS
```tcl
paravar::define varname ?initial_value?
paravar::update_peers peers
```

# DESCRIPTION
The `paravar` module implements a distributed shared memory model using Tcl's variable `trace` mechanism. When a parallel variable is modified on any node, the change is automatically propagated to all other nodes in the cluster.

# COMMANDS
**paravar::define** *varname* ?*initial_value*?
Registers a variable as a "Parallel Variable".
- *varname*: The name of the variable (will be resolved to a fully qualified name).
- *initial_value*: Optional initial value.

**paravar::update_peers** *peers*
Updates the internal list of peers that should receive variable updates. This is typically called automatically by the `discovery` module.

# MECHANISM
1. When `define` is called, a `trace add variable write` is placed on the variable.
2. Any `set` operation on the variable triggers the `sync_handler`.
3. The `sync_handler` uses `paracomms::send_command` to call `remote_update` on all peers.
4. To prevent infinite loops, an internal `syncing` flag is used during remote updates.

# SEE ALSO
paratcl(n), paracomms(n)
