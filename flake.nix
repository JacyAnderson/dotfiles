{
  description = "dotfiles";

  inputs = {
    # Use `github:NixOS/nixpkgs/nixpkgs-26.05-darwin` to use Nixpkgs 26.05.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    # Use `github:nix-darwin/nix-darwin/nix-darwin-26.05` to use Nixpkgs 26.05.
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, home-manager, nixpkgs }:
    let
      lib = nixpkgs.lib;

      # Every hosts/<name>.nix becomes a darwinConfigurations.<name> entry, and
      # <name> is that machine's `scutil --get LocalHostName`. Adding a machine
      # is ADDING A FILE: this file is never edited to describe one, so no
      # checkout ever has to diverge from git just to build itself.
      #
      # Nix only sees git-tracked files, so a freshly written host file must be
      # `git add`ed before it evaluates. bootstrap.sh does that for you.
      hostNames = map (lib.removeSuffix ".nix")
        (builtins.filter (lib.hasSuffix ".nix")
          (builtins.attrNames (builtins.readDir ./hosts)));

      hosts = lib.genAttrs hostNames (name: import (./hosts + "/${name}.nix"));

      # `host` and `hostName` are the two halves of machine identity: `host` is
      # what the machine IS (user, system, profile), `hostName` is what the
      # machine is CALLED. hostName is passed deliberately even though no module
      # reads it yet, so a module can key on the machine's own name without
      # shelling out to scutil.
      mkHost = hostName: host: nix-darwin.lib.darwinSystem {
        specialArgs = { inherit host hostName; user = host.user; };
        modules = [
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Adopting onto a configured Mac: back up existing real files
            # (~/.zshrc, ~/.claude/settings.json, ...) instead of aborting.
            home-manager.backupFileExtension = "pre-hm";
            home-manager.extraSpecialArgs = { inherit host hostName; user = host.user; };
            home-manager.users.${host.user} = import ./home.nix;
          }
        ];
      };
    in
    {
      # A half-finished host file breaks only its own attribute; every other
      # machine still evaluates and builds. `nix flake check` is the command
      # that deliberately evaluates all of them.
      darwinConfigurations = lib.mapAttrs mkHost hosts;
    };
}
