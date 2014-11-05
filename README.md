dotfiles
========

my dotfiles

###### setup

    THIS_REPO = https://github.com/sea-grass/dotfiles.git
    git clone $THIS_REPO dotfiles
    cd dotfiles
    ./makesymlinks.sh
    source ~/.bash_profile
    xrdb -merge ~/.Xresources

###### what this creates

symlinks to my personal config files:

| config file   | in use by... |
| .screenrc     | GNU Screen   |
| .vimrc        | Vim          |
| .bash_profile | bash         |
| .Xresources   | X11          |

 - .screenrc
 - .vimrc
 - .bash_profile
 - .Xresources
