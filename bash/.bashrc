#
# ~/.bashrc
#

START=`date +%s`

. ~/.bash/aliases
. ~/.bash/env
. ~/.bash/config
. ~/.bash/goodies
. ~/.bash/tools/tt.bash

END=`date +%s`

echo ".bashrc took " $(($END-$START)) " seconds"
VITASDK=/usr/local/vitasdk
PATH="$VITASDK/bin:$PATH"
set mouse=a
set ttymouse=xterm2
