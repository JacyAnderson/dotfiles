{ config, pkgs, user, host, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  # User-level things every machine shares. Anything per-context (git identity,
  # for one) lives in the profile named by hosts/<LocalHostName>.nix.
  imports = [ ./profiles/${host.profile}/home.nix ];

  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    # Brew on PATH, declared here instead of relying on an unmanaged ~/.zprofile.
    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
    initContent = ''
      bindkey '^f' autosuggest-accept

      export PATH="$HOME/.local/bin:$PATH"

      # node via nvm (not nix-managed; projects pin their own node versions)
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      export GITHUB_TOKEN="$(gh auth token)"

      # Claude Code fleet helpers (ccfleet, ccpeek, ccwatch, ccnew)
      source ~/.dotfiles/home/claude/fleet-helpers.sh
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.git = {
    enable = true;
    # Identity itself is per-context, so it lives in profiles/<profile>/home.nix.
    # This is only the safety net: without it, a machine that somehow has no
    # configured identity silently authors commits as
    # jacyanderson@Jacys-MacBook-Air.local, guessed from hostname and gecos.
    # With it, git refuses and says so. A no-op while a default identity is
    # always present, which is exactly when a safety net should be invisible.
    settings.user.useConfigOnly = true;
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.tmux.conf";
  # ~/.claude gets exactly these two symlinks; it's Claude's mutable state dir,
  # so everything else in home/claude/ is reached by ~/.dotfiles path instead.
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/claude/CLAUDE.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
