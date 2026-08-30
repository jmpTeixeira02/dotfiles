{ config, lib, ... }:

{
  _module.args.linkConfig =
    path: config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/${path}";
}
