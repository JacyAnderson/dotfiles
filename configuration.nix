{ user, host, ... }:

{
  # System-level things every machine shares. Anything per-context (Homebrew,
  # for one) lives in the profile named by hosts/<LocalHostName>.nix.
  imports = [ ./profiles/${host.profile}/system.nix ];

  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = host.system; # aarch64-darwin, or x86_64-darwin on Intel

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
}
