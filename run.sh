# Create an ISO image from a directory
xorriso -as mkisofs -o output.iso /path/to/directory

# List contents of an ISO
xorriso -indev image.iso -ls

# Extract contents of an ISO
xorriso -indev image.iso -osirrox on -extract / output_directory