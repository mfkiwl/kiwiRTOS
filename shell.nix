{ pkgs ? import <nixpkgs> { } }:

let
  # Check if we're on Darwin (macOS)
  isDarwin = pkgs.stdenv.isDarwin;
in pkgs.mkShell {
  buildInputs = [
    pkgs.neofetch # System information tool
    pkgs.just # Just runner
    pkgs.zig # Zig compiler
    pkgs.xorriso # ISO image creator
    pkgs.nasm # NASM assembler
    pkgs.cdrtools # CD-ROM tools
    pkgs.qemu # For testing the OS

    # Include tools conditionally based on platform
    (pkgs.lib.optional (!isDarwin) pkgs.grub2) # GRUB bootloader (Linux only)
  ];

  # Shell hook to set up environment
  shellHook = "";
}
