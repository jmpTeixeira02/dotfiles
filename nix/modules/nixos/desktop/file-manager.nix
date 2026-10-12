{
  flake.modules.nixos.file-manager = { pkgs, lib, ... }: {
    services = {
      gvfs.enable = true;
      udisks2.enable = true;
    };

    nixpkgs.overlays = [
      (final: prev: {
        nautilus = prev.nautilus.overrideAttrs (nprev: {
          buildInputs =
            nprev.buildInputs
            ++ (with pkgs.gst_all_1; [
              gst-plugins-good
              gst-plugins-bad
            ]);
        });
      })
    ];
  };
}
