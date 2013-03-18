#------------------------------------------------------------------------------
#          FILE:  zshrc
#   DESCRIPTION:  Executes commands at the start of an interactive session
#        AUTHOR:  Adam Walz <viperlight89@me.com>
#       VERSION:  1.0.0
#------------------------------------------------------------------------------

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Source Boxen
[ -f /opt/boxen/env.sh ] && source /opt/boxen/env.sh

#============================ Customize to your needs =========================

# Changes iTerm profile when using ssh
alias ssh=ssh-with-profile

# Add CUDA directories to PATH
#export PATH=/Developer/NVIDIA/CUDA-5.0/bin:$PATH
#export DYLD_LIBRARY_PATH=/Developer/NVIDIA/CUDA-5.0/lib:$DYLD_LIBRARY_PATH
