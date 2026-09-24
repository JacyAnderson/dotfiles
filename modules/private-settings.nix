# A personal settings repo that lives outside this public one and ships its own
# installer. The repo's URL is deliberately not an option: bootstrap.sh asks for
# it when it clones, so no tracked file ever names a private repo.
{
  config,
  lib,
  user,
  ...
}:

let
  cfg = config.my.privateSettings;
in
{
  options.my.privateSettings = {
    enable = lib.mkEnableOption "a personal settings repo whose installer runs on every switch";

    path = lib.mkOption {
      type = lib.types.str;
      example = "code/my-settings";
      description = "Where the repo is cloned, relative to the home directory.";
    };

    installer = lib.mkOption {
      type = lib.types.str;
      default = "bin/install.sh";
      description = "Idempotent, non-interactive script inside the repo, run as the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user} =
      { config, lib, ... }:
      {
        # Warn instead of failing: a machine without access to the repo, or a
        # broken installer, should still get the rest of its configuration.
        home.activation.privateSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          installer=${lib.escapeShellArg "${config.home.homeDirectory}/${cfg.path}/${cfg.installer}"}
          if [ -x "$installer" ]; then
            PATH="$PATH:/usr/bin:/bin" run "$installer" \
              || warnEcho "private settings: $installer failed"
          else
            warnEcho "private settings: $installer not found; clone the repo there or rerun ./bootstrap.sh"
          fi
        '';
      };
  };
}
