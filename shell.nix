{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    zig # Zig compiler
    xorriso # ISO image creator
    # grub2 # GRUB bootloader
    # efibootmgr # UEFI boot manager
    # os-prober # For detecting other operating systems
  ];
}
