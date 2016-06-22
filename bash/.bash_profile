#
# ~/.bash_profile
#

# When a login shell, or a non-interactive shell with the --login option, is started,
# ~/.bash_profile will be executed (unless the --noprofile option is used)
#
# This means that this will run for:
# - new ssh sessions
# - new tmux windows or panes
#
# This will NOT run for:
# - running bash from command line

[[ -f ~/.bashrc ]] && . ~/.bashrc
