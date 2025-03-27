{ pkgs ? import <nixpkgs> { } }:

let
  # Check if we're on Darwin (macOS)
  isDarwin = pkgs.stdenv.isDarwin;
in pkgs.mkShell {
  buildInputs = with pkgs; [
    zig # Zig compiler
    xorriso # ISO image creator
    qemu # For testing the OS

    # Include tools conditionally based on platform
    (lib.optional (!isDarwin) grub2) # GRUB bootloader (Linux only)
    (lib.optional (!isDarwin) efibootmgr) # UEFI boot manager (Linux only)
    (lib.optional (!isDarwin)
      os-prober) # For detecting other operating systems (Linux only)
    (lib.optional (!isDarwin) mtools) # For FAT filesystem support (Linux only)
    (lib.optional (!isDarwin) parted) # For disk partitioning (Linux only)

    # MacOS alternatives
    (lib.optional isDarwin cdrtools) # For creating bootable CDs/DVDs
    (lib.optional isDarwin
      gptfdisk) # GPT fdisk tools for disk partitioning on macOS
  ];

  # Shell hook to set up environment
  shellHook = ''
    echo "Setting up bootable image creation environment..."

    ${if isDarwin then ''
      echo "🍎 Running on macOS: Using alternative tools for bootable image creation"
      echo "📀 Available tools: mkisofs/genisoimage (from cdrtools)"
      echo ""
      echo "To create a bootable ISO on macOS, you can use a command like:"
      echo "mkisofs -R -b boot/grub/i386-pc/eltorito.img -no-emul-boot -boot-load-size 4"
      echo "        -boot-info-table -o myos.iso isodir/"
      echo ""
      echo "Note: You might need to prepare boot files separately."
    '' else ''
      echo "🐧 Linux environment detected"
      echo "💾 GRUB tools available: grub-mkrescue"
      export PATH=${pkgs.grub2}/bin:$PATH
    ''}
  '';
}
