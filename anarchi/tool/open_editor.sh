#!/bin/bash

editor="$1"

# NAME_SOFT="calux"
NAME_SOFT="anarchic"
REP_SCRIPT="$( echo $0 | sed "s/\(.*\)\/$NAME_SOFT\/tool.*/\1\/$NAME_SOFT/g" )"


# REP_SCRIPT="/media/srv/scripts/$NAME_SOFT"
FILES_2_OPEN="launchInstall.sh,files/{futil,linux-part.sh,custom*,softs-trans,post_install.sh,de/*.conf,lang/{fr_FR*,en_GB*}},iso/{build-iso.sh,initialise},tool/{prepare_$NAME_SOFT,open_editor.sh,${NAME_SOFT}_package},pacinstall.sh"

[ "$editor" == "" ] && editor="kate"

echo "$editor $REP_SCRIPT/{$FILES_2_OPEN} /media/srv/pxe/clonezilla/futil &"

