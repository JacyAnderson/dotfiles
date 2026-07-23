{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";  # needs logout/login to fully apply
      KeyRepeat = 2;          # fast key repeat (needs logout/login)
      InitialKeyRepeat = 15;  # short delay before repeat (needs logout/login)
    };
    dock.autohide = true;
    trackpad.Clicking = true;              # tap to click
  };
  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;  # adopt the pre-existing /opt/homebrew install
  };
  homebrew = {
    enable = true;
    # Staged adoption: "none" for the first verified switch on this machine,
    # then flip to "zap" (remove anything not listed here) and rebuild.
    onActivation.cleanup = "none";
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"              # agent multiplexer
      "gh"                 # gh auth token in shell init
      "terminal-notifier"  # fleet-notify.sh banners
      "tmux"               # fleet workflow
      # NOT declared, so zap removes them: boost/cmake/qt@5/pkgconf/qrencode
      # (dead build cruft, zero dependents) and jq (nix-managed in home.nix).
    ];
    casks = [
      "wezterm"  # --force adopts the manually installed app
      # claude-code cask deliberately absent: native install at ~/.local/bin/claude
      # font-hack-nerd-font deliberately absent: nerd-fonts.hack via home.nix
    ];
  };
}
