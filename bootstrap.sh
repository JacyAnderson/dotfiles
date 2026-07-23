#!/usr/bin/env bash
# Takes a fresh Mac from nothing to a built nix-darwin config.
# Run this once. After it finishes, use ./rebuild.sh for every later change.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> Step 1: Determinate Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "==> Step 2: symlink this repo to ~/.dotfiles"
# home.nix resolves its mkOutOfStoreSymlink paths through ~/.dotfiles, so this
# has to exist before the first switch or the build will fail to find them.
ln -sfn "$DIR" ~/.dotfiles

echo "==> Step 3: register this machine"
# This step only ever ADDS hosts/<LocalHostName>.nix. It never rewrites a
# tracked, shared file, so a second machine's checkout never diverges from git
# and can always pull cleanly.
#
# Do this before any sudo call: sudo resets $USER to root, so whoami has to
# run as the real interactive user first.
REAL_USER="$(whoami)"
HOST="$(scutil --get LocalHostName 2>/dev/null || true)"
if [ -z "$HOST" ]; then
  echo "    This Mac has no LocalHostName, which is how the config finds itself."
  echo "    Set one, then re-run:  sudo scutil --set LocalHostName my-mac"
  exit 1
fi
HOST_FILE="$DIR/hosts/${HOST}.nix"

if [ -f "$HOST_FILE" ]; then
  echo "    known machine: $HOST"
  CONFIGURED_USER="$(sed -nE 's/^[[:space:]]*user[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$HOST_FILE" | head -n1)"
  if [ "$CONFIGURED_USER" != "$REAL_USER" ]; then
    echo "    hosts/${HOST}.nix says user \"$CONFIGURED_USER\" but you are \"$REAL_USER\"."
    echo "    Fix that one line in hosts/${HOST}.nix and commit it, then re-run."
    exit 1
  fi
  echo "    macOS user \"$REAL_USER\" matches, nothing to do."
else
  echo "    new machine: $HOST (macOS user: $REAL_USER)"
  read -r -p "    profile [work]: " PROFILE
  PROFILE="${PROFILE:-work}"
  # configuration.nix imports the profile's system.nix and home.nix imports its
  # home.nix, so a half-built profile has to fail here with something actionable
  # rather than deep inside Nix evaluation in step 4.
  if [ ! -f "$DIR/profiles/$PROFILE/system.nix" ] || [ ! -f "$DIR/profiles/$PROFILE/home.nix" ]; then
    echo "    The \"$PROFILE\" profile does not exist yet."
    echo "    Create both of these files, commit them, then re-run ./bootstrap.sh:"
    echo "      profiles/$PROFILE/system.nix   (imported by configuration.nix)"
    echo "      profiles/$PROFILE/home.nix     (imported by home.nix)"
    echo "    Copy profiles/personal/ as a starting point, but give this machine"
    echo "    its own git identity - that separation is the point of profiles."
    echo "    No host file was written."
    exit 1
  fi
  case "$(uname -m)" in
    arm64) SYSTEM="aarch64-darwin" ;;
    x86_64) SYSTEM="x86_64-darwin" ;;
    *) echo "    unsupported architecture: $(uname -m)"; exit 1 ;;
  esac
  mkdir -p "$DIR/hosts"
  cat > "$HOST_FILE" <<EOF
# $HOST - registered by bootstrap.sh on $(date +%Y-%m-%d).
{
  user = "$REAL_USER";
  system = "$SYSTEM";
  profile = "$PROFILE";
}
EOF
  # Nix only reads git-tracked files out of a flake, so an untracked host file
  # is invisible to the build. Stage it now; step 4 would otherwise fail with
  # "path does not exist in Git repository".
  git -C "$DIR" add "$HOST_FILE"
  echo "    wrote and staged hosts/${HOST}.nix ($PROFILE profile, $SYSTEM)."
  echo "    Commit and push it once the build below succeeds."
fi

echo "==> Step 4: first darwin-rebuild switch (pinned to nix-darwin-26.05)"
# darwin-rebuild doesn't exist yet on a fresh machine, so run it straight
# from the flake this once. After this, rebuild.sh works normally.
# This fetches the darwin-rebuild tool from the nix-darwin-26.05 release branch,
# not the exact flake.lock revision. The system config it applies is still pinned
# by this repo's flake.lock.
# sudo resets PATH to a secure default that excludes /nix/.../bin, so a
# freshly installed `nix` would not be found under sudo even though it's
# on PATH here. Resolve the absolute path first and invoke that instead.
NIX_BIN="$(command -v nix)"
# No flake attribute: darwin-rebuild defaults it to
# darwinConfigurations.$(scutil --get LocalHostName), which step 3 just made
# sure exists.
sudo "$NIX_BIN" run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake ~/.dotfiles
# If this still fails with "nix: command not found", open a new terminal
# (Determinate adds nix to new shells' PATH) and re-run ./bootstrap.sh.

echo "==> Done. Use ./rebuild.sh for future changes."
