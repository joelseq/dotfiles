#!/usr/bin/env bash
set -euo pipefail

git clone https://github.com/joelseq/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
