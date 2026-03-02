# NAME
hosts.para - ParaTcl cluster configuration file

# DESCRIPTION
The `hosts.para` file defines the potential nodes available to a ParaTcl cluster. It is a simple line-based text file used by the `hardware` module to prepare the MPI runtime environment.

# FORMAT
- One hostname or IP address per line.
- Empty lines are ignored.
- Comments start with the `#` character and are ignored.

# CONNECTIVITY REQUIREMENTS
ParaTcl requires **passwordless SSH** access to all nodes listed in `hosts.para`.
During initialization, the `hardware::manage_hosts` procedure will:
1. Parse `hosts.para`.
2. Attempt a non-interactive SSH connection (`ssh -o BatchMode=yes`) to each host.
3. If the connection fails or requires a password, the host is discarded.
4. Valid hosts are written to `hosts.para.runtime`.

# RECOMMENDATION
To set up a node for ParaTcl, ensure your public key is in the node's `~/.ssh/authorized_keys` file. You can use the following command:
```bash
ssh-copy-id username@hostname
```

# EXAMPLE
```text
# Master node
localhost

# Compute nodes
192.168.1.10
192.168.1.11
node03.cluster.local
```

# SEE ALSO
hardware(n), bootknife(7)
