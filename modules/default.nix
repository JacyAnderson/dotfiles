# Opt-in features. Every module here is imported on every machine and does
# nothing until my.<name>.enable is set, normally in the `my` attrset of
# hosts/<LocalHostName>.nix. Listing a module here makes it available, not active.
{
  imports = [
    ./opensuperwhisper.nix
  ];
}
