# Set default variables
ZIG_LOCAL_CACHE_DIR := env_var_or_default('ZIG_LOCAL_CACHE_DIR', home_directory() + "./.cache/zig")

alias r := run
alias b := build
alias c := clean
alias ch := check
alias f := format
alias d := docs

# Run a package
run *args='x86':
  zig build run -Dtarget_arch={{args}}

# Build the project
build *args='x86':
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
  mkdir -p {{ZIG_LOCAL_CACHE_DIR}}
  zig build docs -Dtarget_arch=x86
