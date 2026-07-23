#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
# No "#mac": with no flake attribute, darwin-rebuild defaults to
# darwinConfigurations.$(scutil --get LocalHostName), so this one script is
# correct on every machine that has a hosts/<LocalHostName>.nix.
exec sudo darwin-rebuild switch --flake ~/.dotfiles
