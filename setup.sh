#!/usr/bin/env bash
set -euo pipefail

if [[ -d ~/dotfiles ]]; then
  git -C ~/dotfiles pull
else
  git clone https://github.com/joelseq/dotfiles.git ~/dotfiles
fi
~/dotfiles/bootstrap.sh
