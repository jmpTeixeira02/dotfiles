{
  config,
  pkgs,
  lib,
  ...
}:

{

  environment.systemPackages = [ pkgs.mergerfs ];

  fileSystems."${config.mySystem.poolMount}" = {
    fsType = "fuse.mergerfs";
    device = "/mnt/disk1:/mnt/disk2";
    options = [
      "defaults"
      "nonempty"
      "allow_other"
      "use_ino"
      "cache.files=partial"
      "dropcacheonclose=true"
      "category.create=epmfs"
    ];
  };
}
