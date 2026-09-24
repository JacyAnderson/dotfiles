# Settings go through `defaults import` on every switch: declared keys beat
# edits made in the app, undeclared keys are left alone. Key names come from
# AppPreferences.swift upstream. Microphone and Accessibility grants are TCC
# state no config can set, so the app asks for them on first launch.
{
  config,
  lib,
  pkgs,
  user,
  host,
  ...
}:

let
  cfg = config.my.opensuperwhisper;
  domain = "ru.starmel.OpenSuperWhisper";

  # The three models the app itself offers for download, pinned to one
  # revision of the Hugging Face repo so the hashes stay valid.
  models = {
    ggml-large-v3-turbo-q5_0 = "394221709cd5ad1f40c46e6031ca61bce88931e6e088c188294c6d5a55ffa7e2"; # "Turbo V3 small", 574 MB
    ggml-large-v3-turbo-q8_0 = "317eb69c11673c9de1e1f0d459b253999804ec71ac4c23c17ecf5fbe24e259a1"; # "Turbo V3 medium", 874 MB
    ggml-large-v3-turbo = "1fc70f774d38eb169993ac391eea357ef47c88757ef72ee5943879b7e8e2bc69"; # "Turbo V3 large", 1.6 GB
  };
  modelRevision = "5359861c739e955e79d9a303bcbc70fb988958b1";

  # The app lists and loads models from this directory (WhisperModelManager.swift).
  modelDir = "Library/Application Support/${domain}/whisper-models";
  modelFile = "${cfg.model}.bin";
in
{
  options.my.opensuperwhisper = {
    enable = lib.mkEnableOption "OpenSuperWhisper local dictation";

    model = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum (lib.attrNames models));
      default = null;
      example = "ggml-large-v3-turbo-q5_0";
      description = ''
        Whisper model to fetch and select. With null, the app's first-run
        onboarding downloads one instead.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = {
        initialPrompt = "nix-darwin, home-manager, herdr";
      };
      description = "Extra keys for the ${domain} defaults domain.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = host.system == "aarch64-darwin";
        message = "my.opensuperwhisper: the opensuperwhisper cask is Apple Silicon only.";
      }
      {
        assertion = config.homebrew.enable;
        message = "my.opensuperwhisper: installs through Homebrew, which this profile does not enable.";
      }
    ];

    homebrew.casks = [ "opensuperwhisper" ];

    my.opensuperwhisper.settings = {
      # Ctrl+Option+Space (kVK_Space, controlKey|optionKey). The app's own
      # defaults, Option+` and right Option alone, swallow the dead keys used to
      # type accents. A non-"none" modifierOnlyHotkey disables this combination
      # in favour of a lone modifier key.
      KeyboardShortcuts_toggleRecord = lib.mkDefault ''{"carbonKeyCode":49,"carbonModifiers":6144}'';
      modifierOnlyHotkey = lib.mkDefault "none";
      holdToRecord = lib.mkDefault true;
      whisperLanguage = lib.mkDefault "en";
      suppressBlankAudio = lib.mkDefault true;
      addSpaceAfterSentence = lib.mkDefault true;
    }
    // lib.optionalAttrs (cfg.model != null) {
      selectedEngine = lib.mkDefault "whisper";
      selectedWhisperModelPath = "${config.users.users.${user}.home}/${modelDir}/${modelFile}";
      # Onboarding exists to pick a model, but on first launch it also
      # overwrites the language and switches the hotkey to right Option, so
      # skip it once a model is declared. Left unset otherwise: forcing false would bring
      # onboarding back after every switch.
      hasCompletedOnboarding = true;
    };

    home-manager.users.${user} = {
      targets.darwin.defaults.${domain} = cfg.settings;

      home.file = lib.mkIf (cfg.model != null) {
        "${modelDir}/${modelFile}".source = pkgs.fetchurl {
          url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/${modelRevision}/${modelFile}";
          sha256 = models.${cfg.model};
        };
      };
    };
  };
}
