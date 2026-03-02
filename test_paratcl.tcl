source paratcl.tcl
puts "--- TEST STARTED ---"
# We avoid calling init directly to avoid the event loop
::hardware::detect
::hardware::status
set h [::hardware::manage_hosts]
puts "Managed hosts: $h"
puts "--- TEST ENDED ---"
