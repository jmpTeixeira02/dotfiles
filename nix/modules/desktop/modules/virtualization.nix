{
  flake.modules.nixos.virtualization = { pkgs, ... }: {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    services.qemuGuest.enable = true;
    services.spice-vdagentd.enable = true;

    environment.systemPackages = [
      pkgs.qemu
    ];
  };
}
