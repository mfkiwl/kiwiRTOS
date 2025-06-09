#!/bin/bash

# Creates a bootable disk image from a kernel image
# Usage:
#    docker.sh base_image image_name

#
#  Private Impl
#

build_image() {
  local base_image="${1}"
  local image_name="${2}"

  docker pull ${base_image}
	docker build . -t ${image_name} --build-arg BASE_IMAGE=${base_image}
}

# Main script logic
set -euo pipefail # Exit on error, print the error message
if [ $# -eq 2 ]; then
  build_image "$1" "$2"
else
  echo "Usage: $0 base_image image_name"
  exit 1
fi
