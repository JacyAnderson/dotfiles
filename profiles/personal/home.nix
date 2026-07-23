# Personal context, user layer. Imported by home.nix based on the `profile`
# field in hosts/<LocalHostName>.nix.
#
# Anything true of this context but not of every machine belongs here. home.nix
# keeps only what every machine shares.
{ ... }:

{
  # Git identity for this context. One context, one identity, so no includeIf
  # exceptions are needed - this default covers every repo on the machine,
  # including no-mistakes' opaque mirrors under ~/.no-mistakes/repos/.
  programs.git.settings.user = {
    name = "Jacy Anderson";
    email = "jacyjamesanderson@gmail.com";
  };
}
