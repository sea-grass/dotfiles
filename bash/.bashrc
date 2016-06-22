#
# ~/.bashrc
#

START=`date +%s`

. ~/.bash/aliases
. ~/.bash/env
. ~/.bash/config

END=`date +%s`

echo ".bashrc took " $(($END-$START)) " seconds"
