alias r := run
alias b := build
alias i := image
alias c := clean
alias db := debug
alias ch := check
alias f := format
alias d := docs

# Run a package with specified architecture
# Usage: just run [arch=x86_64]
run arch='x86_64':
  zig build run -Dtarget_arch={{arch}}

# Build the project
# Usage: just build [arch=x86_64]
build arch='x86_64':
  zig build -Dtarget_arch={{arch}}

# Build the project
# Usage: just image [arch=x86_64]
image arch='x86_64':
  zig build image -Dtarget_arch={{arch}}

# Debug the project
# Usage: just debug [arch=x86_64]
debug arch='x86_64':
  zig build debug -Dtarget_arch={{arch}}

# Clean the project
clean:
  @# Remove cached files
  rm -rf .zig-cache zig-out

# Run code quality tools
check:
  zig build check

# Format the project
format:
  zig fmt .

# Generate documentation
docs arch='x86_64':
  zig build docs -Dtarget_arch={{arch}}
