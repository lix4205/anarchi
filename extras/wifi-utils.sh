#!/bin/bash

# This script need futil
DIR_SRC="$(dirname $0)"
source $DIR_SRC/src/sources_files.sh $DIR_SRC/src/bash-utils.sh $DIR_SRC/src/futil $DIR_SRC/src/net-utils $DIR_SRC/src/doexec

out_netctl () {
	cp $1/etc/netctl/examples/wireless-wpa $1/etc/netctl/$NAME_CON
	sed -i "s/Description=.*/Description='Connection on access point $ESSID'/" $1/etc/netctl/$NAME_CON
	sed -i "s/Interface=.*/Interface=$I_W/" $1/etc/netctl/$NAME_CON
	sed -i "s/Security=.*/Security=$SEC_NET/" $1/etc/netctl/$NAME_CON
	sed -i "s/ESSID=.*/ESSID='$ESSID'/" $1/etc/netctl/$NAME_CON
	sed -i "s/Key=.*/Key='$(echo "$PASS_NET_CH" | openssl enc -base64 -d)'/" $1/etc/netctl/$NAME_CON
# echo "Description='Connection on access point $ESSID'
# Interface=$I_W
# Connection=wireless
# 
# Security=$SEC_NET
# IP=dhcp
# 
# ESSID='$ESSID'
# # Prepend hexadecimal keys with \\\"
# # If your key starts with \", write it as '\"\"<key>\"'
# # See also: the section on special quoting rules in netctl.profile(5)
# Key='$(echo "$PASS_NET_CH" | openssl enc -base64 -d)'
# # Uncomment this if your ssid is hidden
# #Hidden=yes
# # Set a priority for automatic profile selection
# #Priority=10
# " 
}

con_wpa_supplicant() {
	[ ! -e $1/etc/wpa_supplicant/wpa_supplicant-$I_W.conf ] && echo "ctrl_interface=/run/wpa_supplicant
update_config=1" > $1/etc/wpa_supplicant/wpa_supplicant-$I_W.conf
	[ -e $1/etc/wpa_supplicant/wpa_supplicant-$I_W.conf ] && rid_continue "Ajouter le point d'accès \"%s\" dans \"%s\" ?" "$ESSID" "/etc/wpa_supplicant/wpa_supplicant-$I_W.conf" && wpa_passphrase $ESSID $(echo "$PASS_NET_CH" | openssl enc -base64 -d) >> $1/etc/wpa_supplicant/wpa_supplicant-$I_W.conf
	if [[ -z $1 ]]; then
		if check_command -q "systemctl"; then
			if ! systemctl is-enabled wpa_supplicant@$I_W  --quiet && rid_continue "Lancer \"%s\" au démarrage ?" "${methods[$TYPE_CON]}"; then
				netman_check
				exe systemctl enable wpa_supplicant@$I_W && exe systemctl enable dhcpcd@$I_W
			fi
			if rid_continue "Lancer la connexion ?"; then
				netman_stop
				exe systemctl start wpa_supplicant@$I_W && exe systemctl start dhcpcd@$I_W
			fi
		else
			wpa_supplicant -B -D nl80211,wext -i $I_W -c <(wpa_passphrase "$ESSID" "$(echo "$PASS_NET_CH" | openssl enc -base64 -d)")
			check_command -q "dhclient" && dhclient $I_W || ( check_command -q "dhcpcd" && dhcpcd $I_W )
		fi
	fi

}

con_netctl() {
	out_netctl > $1/etc/netctl/$NAME_CON
	if [[ -z $1 ]]; then
		if rid_continue "Lancer \"%s\" au démarrage ?" "$NAME_CON"; then
			netman_check
			exe netctl enable $NAME_CON
		fi
		if rid_continue "Lancer la connexion \"%s\" ?" "$NAME_CON"; then
			netman_stop
			exe netctl start $NAME_CON
		fi
	fi
}

con_netman() {
	if [[ -z $1 ]]; then
		echo "nmcli dev wifi connect $ESSID password $(echo "$PASS_NET_CH" | openssl enc -base64 -d) iface $I_W"
		if check_command -q "systemctl"; then
			if ! systemctl is-enabled NetworkManager --quiet; then
				rid_continue "Lancer \"%s\" au démarrage ?" "${methods[$TYPE_CON]}" && exe systemctl enable NetworkManager
			fi
			if rid_continue "Lancer la connexion ?"; then
				! systemctl is-active NetworkManager --quiet && exe systemctl start NetworkManager
				exe nmcli dev wifi con "$ESSID" password $(echo "$PASS_NET_CH" | openssl enc -base64 -d) name "$NAME_CON" && nmcli c mod "$NAME_CON" connection.permissions user
			fi
		else
			:
		fi
	else
		# It seems to be useless...
# 		 && nmcli c mod \"$NAME_CON\" connection.permissions user && rm \$0
		caution "Il n'est pas possible d'activer un nouveau profil de connexion tant que NetworkManager n'est pas lancé !\n%s Executez la commande suivante pour créer le profil une fois NetworkManager lancé...\nnmcli dev wifi con \"$ESSID\" password \$(echo \"$PASS_NET_CH\" | openssl enc -base64 -d)  name \"$NAME_CON\"\n%s Cette commande est disponible dans $1/init_nm.sh. Lancez bash \"%s\" pour l'executer." "==>" "==> " "$1/init_nm.sh"
		echo -e "#!/bin/bash\nnmcli dev wifi con \"$ESSID\" password \$(echo \"$PASS_NET_CH\" | openssl enc -base64 -d)  name \"$NAME_CON\"" > $1/init_nm.sh
	fi
}

rid_wifi() {
	[[ -e "/tmp/$1" ]] && source /tmp/$1 || die "Unable to find \"/tmp/$1\" !"
	[[ ! -z $2 ]] && TYPE_CON=$2 || die "Connection not set !"
	[[ ! -z $3 ]] && NAME_CON=$3 || die "Name connection not set !"
	[[ ! -z $4 ]] && PATH_CON=$4
	
	case $TYPE_CON in
		# WPA Supplicant
		1|wpa_supplicant)
			exist_install "wpa_supplicant" || {
				error "wpa_supplicant n'est pas installé !"
				msg_n "32" "32" "Veuillez installer \"%s\" avec \"%s\"" "wpa_supplicant" "pacman -S wpa_supplicant"
				exit
			}
			con_wpa_supplicant "$PATH_CON"
			
		;;
		# Netctl
		2|netctl)
			exist_install "wpa_supplicant" || {
				error "wpa_supplicant n'est pas installé !"
				msg_n "32" "32" "Veuillez installer \"%s\" avec \"%s\"" "wpa_supplicant" "pacman -S wpa_supplicant"
				exit
			}
			con_netctl "$PATH_CON"
		;;
		# NetworkManager
		3|networkmanager)
			exist_install "NetworkManager" "networkmanager" || {
				error "networkmanager n'est pas installé !"
				msg_n "32" "32" "Veuillez installer \"%s\" avec \"%s\"" "networkmanager" "pacman -S networkmanager"
				exit
			}
			con_netman "$PATH_CON"
		;;
	esac
	return 0
}

set_wifi() {
#	Recuperation du SSID
	ESSID="$1"
	if [[ -z "$ESSID" ]]; then
		ESSID="$( get_text "$_choix_ssid" )" || return 1; 
	fi
#	Recuperation du password dans un fichier, sinon l'utilisateur est invite a le taper
	if [[ -e /tmp/$ESSID ]]; then
		rid_continue "$_pass_file" "/tmp/$ESSID"  && source /tmp/$ESSID && msg_n2 "$_read_pass" "/tmp/$ESSID"; 
	else
		while [[ "$PASS_NET_CH" == "" ]]; do
			PASS_NET_CH=$( clear_line && str2ssl "$(rid "$_pass_net"  "$ESSID" " " )" );
			[[ "$PASS_NET_CH" == "$(str2ssl "q")" ]] && return 1
			[[ "$PASS_NET_CH" == "" ]] && choix2error "$_error_pass" "sécurisé"
		done
		clear_line
# 		On genere le fichier /tmp/$ESSID contenant les infos nécessaires a la connexion.
		echo -e "I_W=$I_W\nESSID=$ESSID\nSEC_NET=$SEC_NET\nPASS_NET_CH=\"$PASS_NET_CH\"" > /tmp/$ESSID && msg_n2 "Creation du fichier dans %s" "/tmp/$ESSID"
	fi
	return 0;
}

# TODO Utiliser iw...
# Liste les réseau WiFi à proximité, puis demande à l'utilisateur d'en choisir un
list_wifi() {
	i=-1
	I_W=$1
	msg_nn "\r" "$_mess_wait" 
	loading & 
	PID_LOAD=$! 
	while read -r; do
		[[ $REPLY =~ Cell.* ]] && i=$((i+1)) && netw[valid_$i]=1
		[[ $REPLY =~ ESSID.* ]] && netw[ssid_$i]="$( echo $REPLY | sed "s/.*ESSID/ESSID/g")" 
		[[ $REPLY =~ Quality.* ]] && netw[qual_$i]="${REPLY//*Quality=/}" && netw[qual_$i]=${netw[qual_$i]//\/*/} 
		[[ $REPLY =~ WEP* ]] && netw[sec_$i]="WEP" && netw[sec_net_$i]="wep"
		[[ $REPLY =~ "WPA Version 1" ]] && netw[sec_$i]="WPA" && netw[sec_net_$i]="wpa"
		[[ $REPLY =~ "WPA2 Version" ]] && netw[sec_$i]="WPA2" && netw[sec_net_$i]="wpa"
		[[ $REPLY =~ PSK* ]] && netw[auth_$i]="/PSK" 	
	done < <(iwlist $I_W scan)
	disown 
	[[ ! -z $PID_LOAD ]] && kill $PID_LOAD 
	[[ $i -eq -1 ]] && sleep 2 && list_wifi $I_W && exit
	clear_line
	msg_nn "\r" "$_nb_net" "$((i+1))"
	out_n "  0)"  "32" "32" "Ajouter un réseau caché\n"
	j=0
	while [[ $j -lt $((i+1)) ]]; do
		PSK="    "  && [[ ${netw[auth_$j]} != "" ]] && PSK=${netw[auth_$j]}
		SEC="   --   " && [[ ${netw[sec_$j]} != "" ]] && SEC="${netw[sec_$j]}$PSK$([[ "${netw[sec_$j]}" == "WPA" ]] && printf " ")"
		out_n " $( [[ $j -lt 9 ]] && echo " ")$((j+1)))"  "32" "32" "$((${netw[qual_$j]}*10/7))/100"
		printf " | $SEC | ">&2
		msg_nn_end "${netw[ssid_$j]}"
		j=$((j+1))
	done
	NET_CH=0
	while  [[ $NET_CH -eq 0 ]] || [[ ${netw[valid_$((NET_CH-1))]} != 1 ]]; do
		NET_CH=$( rid "$_choix_net" "q" "r")
		[[ "$NET_CH" == "0" ]] && set_wifi
# 		choix2error "Pas encore disponible !"
		[[ "$NET_CH" == "q" ]] && msg_n "End" && exit
		[[ "$NET_CH" == "r" ]] && msg_nn "Reload" && list_wifi $I_W
	done
	ESSID=$(echo ${netw[ssid_$((NET_CH-1))]} | sed "s/.*ESSID:\"\(.*\)\"/\1/g" )
	SEC_NET=${netw[sec_net_$((NET_CH-1))]}
}

conf_net_wifi () {
	I_W=$1
	OP=0
# 	msg_n "Sélection de la méthode de connexion"
# 	printf "\t1) WPA Supplicant (default)\n\t2) Netctl\n\t3) NetworkManager\n\t4) Extra\n" >&2
	
	msg_nn "$(rid_menu -q "Sélection de la méthode de connexion" "${valid_methods[@]}")" 
	
	while  [[ $OP -eq 0 ]]; do
		OP=$( rid "Quel type de connexion ? Type '%s' to quit" "q" )
		[[ "$OP" == "q" ]] && printf "\n" && exit 1
		[[ "$OP" == "" ]] && OP=1
		case $OP in 
			1|2|3)
				msg_n "32" "32" "%s sélectionné." "${methods[$OP]}"
				list_wifi $I_W && set_wifi "$ESSID"
				NAME_NETCTL=$( [[ "$OP" != "1" ]] && rid "Entrez un nom pour la connexion. (par defaut:%s)" "$SEC_NET-${ESSID,,}" || echo "$ESSID" ) && [[ $NAME_NETCTL  == "" ]] && NAME_NETCTL="$SEC_NET-${ESSID,,}"
			;;
# 			4) 
# 				OP=0
# 				msg_n "32" "32" "%s sélectionné." "Extras"
# 				msg_n "Sélection de la méthode de connexion"
# 				printf "\t1) Bridge Netctl\n\t2) Bridge Wifi\n\t3) Bonding Netctl\n\t4) Pxe DNSMASQ\n" >&2
# 				while  [[ $OP -eq 0 ]]; do
# 					OP=$( rid_1 "Quel type de connexion ? Type '%s' to quit" "q" )
# 					[[ "$OP" == "q" ]] && printf "\n" && exit
# 					[[ "$OP" == "" ]] && OP=1
# 					case $OP in 
# 						1|2|3|4)
# 							msg_ntin "32" "32" "%s sélectionné." "${extras[$OP]}"
# 						;;
# 						*) OP=0
# 						;;
# 					esac
# 				done
# 				extras $OP
# 				exit
# 			;;
			*) OP=0 ;;
		esac
	done
	[[ -z $2 ]] && rid_wifi "$ESSID" "$OP" "$NAME_NETCTL" || printf "${methods[_$OP]}@$NAME_NETCTL@$ESSID"
}

init_wifi() {
	I_W="$1"
	exist_install "iwlist" "wireless_tools" || {
		error "%s n'est pas installé !" "wireless_tools"
		msg_n "32" "32" "Veuillez installer \"%s\" avec \"%s\"" "wireless_tools" "pacman -S wireless_tools"
		exit
	}

	( [[ -z $I_W ]] || ( ! ip addr | grep -q "$I_W" && error "L'interface %s n'existe pas !" "$I_W")  ) && { I_W="$(list_if "wifi" && ask_if )"; [[ $? -gt 0 ]] && die "Aucun périphérique disponible ! $I_W"; }
	
	if ! ip addr | grep -q $I_W | grep -q UP; then
		caution "L'interface %s n'est pas activée !" "$I_W" 
# 		&& 
		
		if is_root "ip link set up dev $I_W" && msg_nn2 "32" "32" "ip link set up dev %s..." "$I_W"; then
			msg_nn_end "ok"
# 			msg_n "Attention :$I_W"
# 			ip addr | grep $I_W | grep UP
# 			msg_n "Attention :"
# 			
			if ! ip addr | grep -q $I_W | grep -q UP; then 
				is_root 1 "/bin/bash $0 ${@}"
			fi
			msg_n "Attention : $( ip addr | grep $I_W  | grep UP )"
		else	
			msg_nn_end "error !"
			error "Impossible d'activer l'interface \"%s\" !" "$I_W"
			die "Vérifier les drivers pour \"%s\" !" "$I_W"
		fi
	fi
	msg_n "Attention 2: $( ip addr | grep $I_W  | grep UP )"
	conf_net_wifi $I_W $2
}

declare -A netw
declare -A valid_iface
declare -A methods=(
	[1]="WPA Supplicant"
	[2]="Netctl"
	[3]="NetworkManager"
	[_1]="wpa_supplicant"
	[_2]="netctl"
	[_3]="networkmanager"
)

valid_methods=(
	"WPA Supplicant (default)"
	"Netctl"
	"NetworkManager"
	"Extras"
)

_mess_wait="Veuillez patienter, scan en cours..."
_choix_net="Quel reseau ? (Type '%s' to quit, '%s' to reload networks list)"
_nb_net="%s reseau(x) trouve(s)\n"
_choix_ssid="Entrez le SSID"
_pass_file="Utiliser le mot de passe du fichier %s ?"
_pass_net="Veuillez entrer le mot de passe pour %s %s"
_read_pass="Lecture du mot de passe dans %s"
_error_pass="La connexion \"%s\" nécessite un mot de passe !"

I_W="wlan0"
FILE_COMMANDS=/tmp/wifi_util_command
echo -e "#\n#\n# Wifi utils ($(date "+%Y/%m/%d-%H:%M"))\n#\n#\n" >> $FILE_COMMANDS

# $1 Interface wifi
# Si $1 est un fichier, alors on va récupérer les infos directement...
[[ ! -z $1 ]] && { [[ -f /tmp/$1 ]] && rid_wifi $@; } || init_wifi $@
# [[ ! -z $1 ]] && { I_W=$1 && [[ -f /tmp/$I_W ]] && rid_wifi $@; } || init_wifi $@
# echo "Ca va se finir !"
# [[ -f /tmp/$I_W ]] && rid_wifi $@ || init_wifi $@

