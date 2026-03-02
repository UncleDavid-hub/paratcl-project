#!/usr/bin/env tclsh
# ParaTcl Grand Unification - Hardware Diagnostic Tool
# This script verifies your system's readiness for high-performance ParaTcl tasks.

source hardware.tcl

puts "===================================================="
puts "   ParaTcl Grand Unification: Hardware Diagnostic   "
puts "===================================================="
puts "Checking local environment..."

# Perform detection
set results [::hardware::detect]
lassign $results mpi cuda vulkan ssh critcl

# Display Detailed Status
::hardware::status

puts "\nDiagnostic Summary:"
if {$mpi && $ssh} {
    puts "  {X} Cluster Ready: MPI and SSH are configured for multi-node runs."
} else {
    puts "  { } Cluster Limited: Local execution only."
}

if {$cuda} {
    puts "  {X} NVIDIA Acceleration: CUDA is available for Tier 1 offloading."
}
if {$vulkan} {
    puts "  {X} ARM/Pi Acceleration: Vulkan is available for Tier 2 offloading."
}

if {!$cuda && !$vulkan} {
    puts "  {!} No GPU Acceleration: Defaulting to CPU (Tier 3 / Fallback)."
}

if {$critcl} {
    puts "  {X} C-Kernel Ready: 'critcl' is installed for high-performance execution."
}

puts "\nReady for ParaTcl! Use 'tclsh demo.tcl master' to start."
puts "===================================================="
