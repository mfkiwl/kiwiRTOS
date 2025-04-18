{ pkgs ? import <nixpkgs> { } }:

let
  # Check if we're on Darwin (macOS)
  isDarwin = pkgs.stdenv.isDarwin;

  # GRUB cross-compilation: target a 32-bit (i386-pc) environment.
  grubPkgs = import <nixpkgs> { crossSystem = { config = "i686-linux"; }; };

in pkgs.mkShell {
  buildInputs = [
    pkgs.neofetch # System information tool
    pkgs.just # Just runner
    pkgs.zig # Zig compiler
    pkgs.xorriso # ISO image creator
    pkgs.nasm # NASM assembler
    pkgs.cdrtools # CD-ROM tools
    pkgs.qemu # For testing the OS
    pkgs.nixfmt # Nix formatter
    pkgs.parted # Partitioning tool

    # Include tools conditionally based on platform
    (pkgs.lib.optional (!isDarwin) grubPkgs.grub2) # Cross-compiled GRUB for i386-pc
    (pkgs.lib.optional (!isDarwin) pkgs.grub2) # Native GRUB (needed for installation on Linux host
  ];

  # Shell hook to set up environment
  shellHook = ''
    # Set GRUB_DIR to the cross-compiled GRUB installation containing i386-pc modules
    export GRUB_DIR="${grubPkgs.grub2}/lib/grub"
    echo "Cross-compiled GRUB environment loaded from: $GRUB_DIR"
  '';
}