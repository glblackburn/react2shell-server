#!/usr/bin/env bats
#
# BATS tests for Makefile targets and help output
#

@test "make without target shows help with descriptions" {
    run make
    [ "$status" -eq 0 ]
    
    # Check that help output contains target descriptions
    echo "$output" | grep -q "React Version Switcher"
    echo "$output" | grep -q "VULNERABLE VERSIONS"
    echo "$output" | grep -q "FIXED VERSIONS"
    echo "$output" | grep -q "Server Management"
    echo "$output" | grep -q "Framework Switching"
    echo "$output" | grep -q "Testing"
    
    # Check that targets have descriptions (format: "make target - description")
    echo "$output" | grep -qE "make [a-z-]+.*-.*"
    
    # Check for specific targets with descriptions
    echo "$output" | grep -qE "make start.*-.*Start"
    echo "$output" | grep -qE "make stop.*-.*Stop"
    echo "$output" | grep -qE "make test.*-.*Run"
    echo "$output" | grep -qE "make use-vite.*-.*Switch"
    echo "$output" | grep -qE "make use-nextjs.*-.*Switch"
}

@test "make help shows same output as make without target" {
    run make help
    [ "$status" -eq 0 ]
    
    help_output="$output"
    
    run make
    [ "$status" -eq 0 ]
    
    # Both should show the same content
    [ "$output" = "$help_output" ]
}

@test "help output contains all major target categories" {
    run make
    [ "$status" -eq 0 ]
    
    # Check for all major sections
    echo "$output" | grep -q "VULNERABLE VERSIONS"
    echo "$output" | grep -q "FIXED VERSIONS"
    echo "$output" | grep -q "Server Management"
    echo "$output" | grep -q "Other commands"
    echo "$output" | grep -q "Framework Switching"
    echo "$output" | grep -q "Testing"
}

@test "help output shows target descriptions in consistent format" {
    run make
    [ "$status" -eq 0 ]
    
    # Count lines that match the pattern "make target - description"
    # This ensures targets have descriptions
    target_lines=$(echo "$output" | grep -cE "^  make [a-z-]+.*-.*" || echo "0")
    
    # Should have at least 20 targets with descriptions
    [ "$target_lines" -ge 20 ]
}

@test "help output includes version switching targets" {
    run make
    [ "$status" -eq 0 ]
    
    # Check for version switching targets
    echo "$output" | grep -q "make react-19.0"
    echo "$output" | grep -q "make react-19.2.1"
    echo "$output" | grep -q "make vulnerable"
}

@test "help output includes framework switching targets" {
    run make
    [ "$status" -eq 0 ]
    
    # Check for framework switching targets
    echo "$output" | grep -q "make use-vite"
    echo "$output" | grep -q "make use-nextjs"
    echo "$output" | grep -q "make current-framework"
}

@test "help output includes test targets" {
    run make
    [ "$status" -eq 0 ]
    
    # Check for test targets
    echo "$output" | grep -q "make test"
    echo "$output" | grep -q "make test-parallel"
    echo "$output" | grep -q "make test-scanner"
}

@test "help output includes server management targets" {
    run make
    [ "$status" -eq 0 ]
    
    # Check for server management targets
    echo "$output" | grep -q "make start"
    echo "$output" | grep -q "make stop"
    echo "$output" | grep -q "make status"
}
