#!/bin/bash

DIR_SCR="$(dirname "$0")"
DISPLAYMANAGER="$1"
THEUSER="$2"
[[ -z $THEUSER ]] && printf "==> ERROR: Please give me a valid username...\n" 
[[ -z $DISPLAYMANAGER ]] && printf "==> ERROR: Please give me a valid display manager...\n"
# && exit 1; 

[[ ! -e "$DIR_SCR/desktops/node.desktop" ]] && printf "==> ERROR: Unable to find node.desktop !\n" && exit 1; 
[[ ! -e "$DIR_SCR/node.sh" ]] && printf "==> ERROR: Unable to find node.sh !\n" && exit 1; 

(( ! EUID == 0 )) && printf "==> ERROR: You have to be root !\n" && exit 1; 
if [[ ! -z "$DISPLAYMANAGER" ]] && [[ ! -z $THEUSER ]]; then
	if [[ "$DISPLAYMANAGER" == "slim" || "$DISPLAYMANAGER" == "nodm" ]] && [[ ! -z $THEUSER ]]; then 
		su $THEUSER -c "echo exec /usr/bin/node > ~/.xinitrc" 
		printf "Creating /.xinitrc with \"exec /usr/bin/node\"\n"
# 	else
	fi
# else
# 	printf "Aucun Display Manager supporté !\n" 
# 	exit 1
fi
install $DIR_SCR/node.sh /usr/bin/node
printf "Installation de NoDE dans /usr/bin/node\n"
cp $DIR_SCR/desktops/node.desktop /usr/share/xsessions/
printf "Installation de node.desktop dans /usr/share/xsessions/\n"

exit 0;
