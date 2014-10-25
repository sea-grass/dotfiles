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

 - .screenrc
 - .vimrc
 - .bashrc
 - .Xresources
