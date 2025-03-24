alias r := run
alias b := build
alias c := clean
alias ch := check
alias f := format
alias d := docs

# Run a package
run *args='riscv64':
  zig build run -Dtarget_arch={{args}}

# Build the project
build *args='riscv64':
  zig build -Dtarget_arch={{args}}


# Clean the project
clean:
  # Remove cached files
  rm -rf .zig-cache zig-out

# Run code quality tools
check:
  zig build check

# Format the project
format:
  zig fmt .

# Generate documentation
docs:
  zig build docs -Dtarget_arch=riscv64

