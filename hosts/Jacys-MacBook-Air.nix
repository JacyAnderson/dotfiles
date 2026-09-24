# Jacys-MacBook-Air - the personal Mac.
#
# The file name must equal this machine's `scutil --get LocalHostName`, because
# darwin-rebuild resolves the flake attribute from LocalHostName when no #attr
# is given. That is what lets ./rebuild.sh take no arguments on any machine.
#
# Adding a machine means adding a file next to this one. Nothing tracked and
# shared ever gets rewritten to describe a single machine.
{
  user = "jacyanderson";
  system = "aarch64-darwin"; # x86_64-darwin on an Intel Mac
  profile = "personal";

  # Opt-in modules from modules/. Anything not listed here stays off.
  my = {
    opensuperwhisper = {
      enable = true;
      model = "ggml-large-v3-turbo-q5_0";
    };
  };
}
