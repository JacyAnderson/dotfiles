# Personal context, system layer. Imported by configuration.nix based on the
# `profile` field in hosts/<LocalHostName>.nix.
#
# Homebrew lives here rather than in configuration.nix on purpose: the package
# set, the adoption strategy, and whether Homebrew is managed at all are
# per-context answers. Owning them here lets another profile give a different
# answer instead of fighting a shared definition with lib.mkForce.
{ config, user, ... }:

let
  brewPrefix = config.homebrew.prefix;
  pgDataDir = "${brewPrefix}/var/postgresql@16";
  pgLog = "${brewPrefix}/var/log/postgresql@16.log";
in
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
      "postgresql@16" # local dev database, run by launchd.user.agents.postgresql below
      # NOT declared, so zap removes them: boost/cmake/qt@5/pkgconf/qrencode
      # (dead build cruft, zero dependents) and jq (nix-managed in home.nix).
    ];
    casks = [
      "wezterm" # --force adopts the manually installed app
      # claude-code cask deliberately absent: native install at ~/.local/bin/claude
      # font-hack-nerd-font deliberately absent: nerd-fonts.hack via home.nix
    ];
  };

  # `brew services start` fails on the pinned Homebrew 6.0.1 (the formula's
  # service block uses `stop_timeout`), so launchd runs the Homebrew binary on
  # its default data dir directly. The non-homebrew.mxcl label keeps
  # `brew services` from treating this agent as its own.
  launchd.user.agents.postgresql.serviceConfig = {
    Label = "org.nixos.postgresql";
    ProgramArguments = [
      "${brewPrefix}/opt/postgresql@16/bin/postgres"
      "-D"
      pgDataDir
    ];
    # Without a valid locale, postmaster aborts with "became multithreaded during startup".
    EnvironmentVariables.LC_ALL = "en_US.UTF-8";
    WorkingDirectory = brewPrefix;
    RunAtLoad = true;
    KeepAlive = true;
    # launchd stops the agent with SIGTERM, which Postgres treats as a smart
    # shutdown that waits for clients; give it time before launchd SIGKILLs.
    ExitTimeOut = 120;
    StandardOutPath = pgLog;
    StandardErrorPath = pgLog;
  };
}
