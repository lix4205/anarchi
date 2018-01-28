#!/bin/bash

# dirname "$0"
# echo $0

[[ ! -z "$DIR_SCRIPTS" ]] && _dir_src="$DIR_SCRIPTS/src/"
[[ ! -z "$DIR_SCR" ]] && _dir_src="$DIR_SCR/src/"

# echo $DIR_SCR
for _file in "$@"; do 
	if [[ -e  "$_file" ]]; then
		source "$_file";  
	else	
		if [[ -e "$_dir_src$_file" ]]; then
			source "$_dir_src$_file";  
		else
			printf "==> ERROR: File \"%s\" not found\n" "$_dir_src$_file"; 
			exit 1; 
		fi
	fi

done;
# [[ ! -z "$_dir_src$_file" ]] && decompte 2 "Okay !" "Au revoir"
# exit 0
