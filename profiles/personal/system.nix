# Personal context, system layer. Imported by configuration.nix based on the
# `profile` field in hosts/<LocalHostName>.nix.
#
# Homebrew lives here rather than in configuration.nix on purpose: the package
# set, the adoption strategy, and whether Homebrew is managed at all are
# per-context answers. Owning them here lets another profile give a different
# answer instead of fighting a shared definition with lib.mkForce.
{ user, ... }:

{
  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true; # adopt the pre-existing /opt/homebrew install
  };
  homebrew = {
    enable = true;
    # Staged adoption: "none" for the first verified switch on this machine,
    # then flip to "zap" (remove anything not listed here) and rebuild.
    onActivation.cleanup = "none";
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr" # agent multiplexer
      "gh" # gh auth token in shell init
      "terminal-notifier" # fleet-notify.sh banners
      "tmux" # fleet workflow
      # NOT declared, so zap removes them: boost/cmake/qt@5/pkgconf/qrencode
      # (dead build cruft, zero dependents) and jq (nix-managed in home.nix).
    ];
    casks = [
      "wezterm" # --force adopts the manually installed app
      # claude-code cask deliberately absent: native install at ~/.local/bin/claude
      # font-hack-nerd-font deliberately absent: nerd-fonts.hack via home.nix
    ];
  };
}
