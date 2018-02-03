#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

function echo_f() { echo -ne "${@}" >> $LOG_FILE; }
function echo_c() { echo -ne "${@}" >> $LOG_CMD; }

function nodeslide() {
	(( $PREV )) && file="$( prev_slide )" || file="$( next_slide )"
# 	file="$( imgs $PATTERN_DIR )"
	cp "$file" /tmp/.$USER.jpg

	echo_c "\nfbsetbg -a \"$file\""
}

function fluxslide() {
	(( $PREV )) && file="$( prev_slide )" || file="$( next_slide )"
	export DISPLAY=:0.0
	fbsetbg -a "$file" >> $LOG_CMD
	echo_c "\nfbsetbg -a \"$file\""
}

function lxslide() {
	(( $PREV )) && file="$( prev_slide )" || file="$( next_slide )"
# 	echo_c "DISPLAY=$DISPLAY"
	export DISPLAY=:0
	pcmanfm$1 -w  "$file" --wallpaper-mode=screen >> $LOG_CMD
	echo_c "\n$1 -w  \"$file\" --wallpaper-mode=screen"
}

# Work with gnome, cinnamon, mate, xfce
function mateslide() {
# 	(( $PREV )) && file="$( prev_slide )" || 
    file="$( next_slide )"
	cp "$file" ~/.bg.jpg

# 	[[ "$USER" == "dux" ]] && (( ! $PREV )) && (( ! $NEXT )) && command -v mdm >/dev/null && command -v convert >/dev/null && imgs_mdm
}


function next_slide() {
	[[ -z $1 ]] && echo_f "\nDE   | " || echo_f "\n$1"
	
	file="$( imgs $PATTERN_DIR )"
	[[ $? -gt 0 ]] && echo_f "==> ERROR: Fichiers inaccessibles ($DIR_IMGS -> $PATTERN_DIR ) !" && exit 1
	echo "$file"
	echo_f "$( date "+%H:%M:%S" ) = \"$file\" $PREV_IMG"
	echo_c "\n$IMG_VIEWER \"$file\""
}



function check_action() {
    tail -n 1 $LOG_FILE | grep -q "^_$1_$"
    [[ $? -gt 0 ]] && return 0 || return 1
}

function make_action() {
    echo_f "\n_$1_"
}

function start_slide() {
    echo "Lancement..."
}


DIR_SCR="$(dirname $0)"
LOG_FILE="$HOME/img.log"
LOG_CMD="/tmp/comm_imgs.log"
SLEEP_TIME=30
NAME_USER="$USER"
ACTION="$1"
shift
DIR_IMGS="$1"
PATTERN_DIR="$2"

declare -A de=(
    ["nom_de_1"]="lxqt-session"
    ["nom_de_2"]="lxsession"
    ["nom_de_3"]="mate-session"
    ["nom_de_4"]="gnome-shell"
    ["nom_de_5"]="cinnamon-session"
    ["nom_de_6"]="xfce.*-session"
    ["nom_de_7"]="fluxbox"
    
    ["cmd_de_1"]="lxslide \"-qt\""
    ["cmd_de_2"]="lxslide"
    ["cmd_de_3"]="mateslide"
    ["cmd_de_4"]="${de[cmd_de_3]}"
    ["cmd_de_5"]="${de[cmd_de_3]}"
    ["cmd_de_6"]="${de[cmd_de_3]}"
    ["cmd_de_7"]="fluxslide"
)
# Si aucun parametre, alors on lance le diapo avec $0 play
if [[ -z "$ACTION" ]]; then
	echo "\nDémarrage - $( date "+%H:%M:%S" )"
    nohup bash "$0" "init"
    exit $?;
else
    CONTINUE_DIAPO=$(check_action "STOP" && echo 1 || echo 0)
#     Gestion de l'actions stop
    [[ "$ACTION" == "stop" ]] && make_action "STOP" && exit
    
    
    source "$DIR_SCR/rdm_img.sh"

    if [[ -z "$DIR_IMGS" ]] || [[ ! -e "$DIR_IMGS" ]]; then
        echo "Aucun répertoire d'images défini !" 
        [[ -e "/home/$NAME_USER/Pictures" ]] && DIR_IMGS="/home/$NAME_USER/Pictures"
        [[ -e "/home/$NAME_USER/Images" ]] && DIR_IMGS="/home/$NAME_USER/Images"
        [[ -z $DIR_IMGS ]] && exit 2;
        echo "Utilisation de $DIR_IMGS"
    fi
    
    # Selection automatique de l'environnement de bureau
    i=1;
    while [[ -z "$CMD_DE" ]] && [[ ! -z "${de[nom_de_$i]}" ]]; do
        ps -e | grep -q "${de[nom_de_$i]}" && CMD_DE="${de[cmd_de_$i]}" && break
        i=$((i+1))
    done
    [[ -z $CMD_DE ]] && echo "Impossible de trouver un environnement de bureau compatible."
#     echo $CMD_DE
#     exit
    
#     NEXT
    if [[ "$ACTION" == "next" ]]; then
#         On verifie qu'on est pas déjà en train de chercher
        if tail -n 1 $LOG_FILE | grep -q "=" && check_action "NEXT"; then
            make_action "NEXT"
    #         Si le diaporama est stoppé, on cherche quand même une nouvelle image
            (( ! $CONTINUE_DIAPO )) && echo_f "\n$( imgs "jpg" )" && make_action "STOP"
            echo_c "\n"
#         else
#             echo "En train de chercher...="
#             tail -n 1 $LOG_FILE
#             echo ""
        fi
        exit;
    fi

#     Demarrage
    if [[ "$ACTION" == "init" ]]; then
        CONTINUE_DIAPO=1
        make_action "START"
    fi
    
    
    while (( $CONTINUE_DIAPO )); do

        CONTINUE_DIAPO=$(check_action "STOP" && echo 1 || echo 0)
        TIME2CHANGE=$(($(date +%s)+$SLEEP_TIME))
        (( $CONTINUE_DIAPO )) && $CMD_DE
#         echo_f "\n$( imgs "jpg" )"
        while [[ $(date +%s) -lt $TIME2CHANGE ]] && (( $CONTINUE_DIAPO )); do

#             [[ -e $LOG_CMD ]] && ! $(check_action "WAIT") && echo_c "\n"
#             echo "\r_WAIT_ [[ $(date +%s) -lt $TIME2CHANGE ]]" >&2

#             Si on est en plein changement alors on sort de la boucle
        	! check_action "NEXT" && break;

            sleep 1
        done
    done
fi


echo "okay !"
exit 0;





# BEGIN FUNCTIONS

echo_f() { echo -ne "${@}" >> $LOG_FILE; }
echo_c() { echo -ne "${@}" >> $LOG_CMD; }

imgs_mdm () { 
	file="$( next_slide "MDM  | " )"
	cp "$file" $IMG_BG
	# On la converti en png
	redim_function ".png"
	# On sauvegarde l'ancien fond d'écran si la sauvegarde n'existe pas.
	[ ! -f $THEME_MDM/bg.old.png ] && sudo mv $THEME_MDM/bg.png $THEME_MDM/bg.old.png
	# Puis on remplace
	sudo mv "$IMG_BG.png" $THEME_MDM/bg.png
}

nodeslide() {
	(( $PREV )) && file="$( prev_slide )" || file="$( next_slide )"
# 	file="$( imgs $PATTERN_DIR )"
	cp "$file" /tmp/.$USER.jpg

	echo_c "\nfbsetbg -a \"$file\""
}

fluxslide() {
	(( $PREV )) && file="$( prev_slide )" || file="$( next_slide )"
	export DISPLAY=:0.0
	fbsetbg -a "$file" >> $LOG_CMD
	echo_c "\nfbsetbg -a \"$file\""
}

lxslide() {
	(( $PREV )) && file="$( prev_slide )" || file="$( next_slide )"
# 	echo_c "DISPLAY=$DISPLAY"
	export DISPLAY=:0
	pcmanfm$1 -w  "$file" --wallpaper-mode=screen >> $LOG_CMD
	echo_c "\n$1 -w  \"$file\" --wallpaper-mode=screen"
}

# Work with gnome, cinnamon, mate, xfce
mateslide() {
	(( $PREV )) && file="$( prev_slide )" || file="$( next_slide )"
	cp "$file" ~/.bg.jpg

	[[ "$USER" == "dux" ]] && (( ! $PREV )) && (( ! $NEXT )) && command -v mdm >/dev/null && command -v convert >/dev/null && imgs_mdm
}

start_slide() {
	echo_f "\nDémarrage - $( date "+%H:%M:%S" )" 
	nohup bash "$@" &
	return $?
}

next_slide() {
	[[ -z $1 ]] && echo_f "\nDE   | " || echo_f "\n$1"
	local file PREV_IMG="PREV=\"$( cat $LOG_FILE | grep "^DE   | [0-9]" | tail -n 2| head -n 1 | sed "s/.*= \"\(.*\)\" PREV.*/\1/g" )\" " 
	file="$( imgs $PATTERN_DIR )"
	[[ $? -gt 0 ]] && echo_f "==> ERROR: Fichiers inaccessibles ($DIR_IMGS -> $PATTERN_DIR ) !" && exit 1
	echo "$file"
	echo_f "$( date "+%H:%M:%S" ) = \"$file\" $PREV_IMG"
	echo_c "\n$IMG_VIEWER \"$file\""
}

# Retourne de 1 donc c'est pas terrible...
prev_slide() {
	[[ -z $1 ]] && echo_f "\nPREVDE " || echo_f "\nP$1"
	local file="$( cat $LOG_FILE | grep "^DE   | [0-9]" | tail -n 1 | sed "s/.*PREV=\"\(.*\)\".*/\1/g" )" 
	echo "$file"
	echo_f "$( date "+%H:%M:%S" ) = \"$file\""
	echo_c "\n$IMG_VIEWER \"$file\""
}

# Ouvre la derniere image.
open_slide() {
	local file="$( cat $LOG_FILE | grep "^DE   | [0-9]" | tail -n 1 | sed "s/.*PREV=\"\(.*\)\".*/\1/g" )" 
	echo "$file"
}

# On cherche un programme pour ouvrir les images
search_imgviewer() {
	imgvs="eom eog lximage-qt gpicview ristretto"
	for iv in ${imgvs}; do
# 		printf " --> %s\n" "$iv" >&2
		command -v $iv >> /dev/null && IMG_VIEWER="$iv" && break;
	done
# 	printf " --> %s trouvé !\n" "$iv" >&2
# 	return 0;
# 	&& return 1
}
#END

DIR_SCR="$(dirname $0)"
# DIR_SRV="$DIR_SCR/../"
# [[ "$DIR_SCR" == "/usr/share/dists-extra/extras" ]] && DIR_SRV="/media/srv"

IMG_BG="/tmp/bg.jpg"
# Le theme MDM utilisé
THEME_MDM="/usr/share/mdm/themes/Arc-Wise-Userlist"
SLEEP_TIME=30
NEXT=0
PREV=0
STOP=0

source $DIR_SCR/rdm_img.sh
# [[ -z "$DIR_IMGS" ]] && echo_f "Le répertoire \"$DIR_IMGS\" n'existe pas !" && exit 1
if [[ ! -z "$1" ]]; then
    [[ "$1" == "stop" ]] && echo_f "\n_STOP_" && exit
    [[ "$1" == "next" ]] && NEXT=1 && shift && echo_c "\n"
    [[ "$1" == "prev" ]] && PREV=1 && shift && echo_c "\n"
    if [[ "$1" == "open" ]]; then
        search_imgviewer 
        [[ -z $IMG_VIEWER ]] && command -v notify-send >/dev/null && notify-send -t 2000 "Aucune visionneuse d'images !"  && exit 1
        $IMG_VIEWER "$(open_slide)" 
        exit
    fi
    if [[ "$1" == "play" ]]; then
        shift
        start_slide "$0" "$@"
        RES_STARTED=$?
        echo $RES_STARTED
        [[ $RES_STARTED -gt 0 ]] && echo "Une erreur est survenue au lancement de \"nohup bash "$@" &\""
        exit $RES_STARTED;
    fi
else
    echo "Slut!"
fi
# die "$IMG_VIEWER"
# Si c'est la premiere execution du script alors on l'execute en arriere plan...
# if [[ ! -z "$1" ]] && [[ "$1" == "play" ]]; then
# 	shift
# 	start_slide "$0" "$@"
# 	RES_STARTED=$?
# 	echo $RES_STARTED
# 	[[ $RES_STARTED -gt 0 ]] && echo "Une erreur est survenue au lancement de \"nohup bash "$@" &\""
# 	exit $RES_STARTED;
# fi

[[ -e $LOG_FILE ]] && tail -n 1 $LOG_FILE | grep -q _STOP_ && STOP=1

(( ! $NEXT )) && (( ! $PREV )) && (( $STOP )) && exit
[[ "$1" != "1" ]] && ! tail -n 1 $LOG_FILE | grep -q "Démarrage" && [[ "$(tail -n 1 $LOG_FILE)" == "DE   | " || "$(tail -n 1 $LOG_FILE)" == "MDM  | " ]] && exit


if [[ ! -z "$1" ]] && [[ "$1" == "1" ]]; then 
	shift
	start_slide "$0" "$@"
	exit
fi

PATTERN_DIR="$@"

# ! mountpoint -q $DIR_SRV && while ! mountpoint -q $DIR_SRV ; do sleep 1; done 

# BEGIN Chrismas config !!!
[[ $( date +%m ) -eq 12 && $( date +%d ) -gt 8 ]] || [[ $( date +%m ) -eq 1 && $( date +%d ) -lt 15 ]] && [[ -e $DIR_IMGS/Christmas ]] && DIR_IMGS=$DIR_IMGS/Christmas
# END Chrismas config !!!

# # Search the command to open slide
# search_imgviewer

# Changement d'arriere plan pour LXDE/LXQT
ps -aux | grep -v grep | grep -q lxqt-session && lxslide "-qt"
ps -aux | grep -v grep | grep -q lxsession && lxslide 
ps -aux | grep -v grep | grep -q mate-session && mateslide
# ps -aux | grep -v grep | grep -q mdm && mateslide
ps -aux | grep -v grep | grep -q gnome-shell && mateslide
ps -aux | grep -v grep | grep -q cinnamon-session && mateslide
ps -aux | grep -v grep | grep -q xfce.*-session && mateslide
ps -aux | grep -v grep | grep -q fluxbox && fluxslide
# ps -aux | grep -v grep | grep -q auto_launcher.sh && ps -aux | grep -v grep | grep -q lightdm && nodeslide

(( $PREV || $NEXT )) && command -v notify-send >/dev/null && notify-send -t 2000 "Fond d'écran changé." 

# On attend 
TIME2CHANGE=$(($(date +%s)+$SLEEP_TIME))

(( $NEXT || $PREV )) && echo_f "\n_NEXT_ $TIME2CHANGE"
(( $STOP )) && echo_f "\n_STOP_" && exit
(( $NEXT || $PREV )) && exit
while [[ $(date +%s) -lt $TIME2CHANGE ]]; do
	[[ -e $LOG_CMD ]] && ! tail -n 1 $LOG_CMD | grep -q "_WAIT_" && echo_c "\n"
	echo_c "\r_WAIT_ [[ $(date +%s) -lt $TIME2CHANGE ]]"
	tail -n 1 $LOG_FILE | grep -q _NEXT_ && TIME2CHANGE=$(tail -n 1 $LOG_FILE | grep _NEXT_ | awk '{print $2}')
	sleep 1
	tail -n 1 $LOG_FILE | grep -q _STOP_ && exit
done
bash $0 $@ &


