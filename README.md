# anarchi
Ce script est destin&eacute; &agrave; installer la distribution ArchLinux avec un environnement de bureau minimal dans le cadre d'une 
utilisation basique ( Bureautique, Web/Mail, Multimedia ).
<br />Il a &eacute;t&eacute; conçu afin d'installer ArchLinux depuis un syst&egrave;me d&eacute;j&agrave; op&eacute;rationnel ( Voir en bas 
de page pour les distributions support&eacute;es... )
<br />
<br /> Ce script peut aussi effectuer une installation sans disque destin&eacute;e &agrave; être boot&eacute;e en r&eacute;seau ( 
param&egrave;tre "-n nfsroot" )...
# Fonctionnement
ATTENTION : On part du principe que la partition de notre future installation est format&eacute;e et mont&eacute;e sur le syst&egrave;me hôte ! ( 
Hormis pour une installation sans disque... )<br />
Il s'agit ensuite de lancer le script avec<br />
<code>
\# /path/to/the/script/launchinstall.sh /path/to/install
</code><br />
Un seul param&egrave;tre est requis, le dossier dans lequel installer.<br />
<strong>Remarque: </strong>Dans cet exemple, aucun chargeur de d&eacute;marrage ne sera install&eacute; !<br />
Si aucun param&egrave;tre n'a &eacute;t&eacute; pass&eacute;, une s&eacute;rie de question concernant le mat&eacute;riel et la personnalisation du 
syst&egrave;me seront pos&eacute;es. <br />
	Toutefois vous pouvez passez les param&egrave;tres directement, voici une rapide description :
	<ul class="opts_list">
		<li>Le premier param&egrave;tre &agrave; passer est la LOCALE (UTF-8 uniquement) utilis&eacute;e par le syst&egrave;me donc quelque 
chose du type :
	<code>
\# /path/to/the/script/launchinstall.sh en_GB /path/to/install
	</code>
		
		</li>
		<li>Tout comme pacstrap ,on peut ajouter des logiciels particulier en ajoutant les noms des paquets &agrave; la fin de la ligne de 
commande.<br />
		Par exemple pour GIMP et STEAM
\# /path/to/the/script/launchinstall.sh en_GB /path/to/install gimp steam

		
		</li>
		<li>Tout les autres param&egrave;tre peuvent être pass&eacute; de mani&egrave;re al&eacute;atoire
		<ul class="opts_list">
			<!-- Pacstrap options -->
			<li class="opt">-C <span>&lt;config&gt;</span></li>
			<li>Use an alternate config file for pacman</li>
			<li class="opt">-d</li>
			<li>Allow installation to a non-mountpoint directory</li>
			<li class="opt">-G</li>
			<li>Avoid copying the host's pacman keyring to the target</li>
			<li class="opt">-i</li>
			<li>Avoid auto-confirmation of package selections</li>
			<li class="opt">-M</li>
			<li>Avoid copying the host's mirrorlist to the target</li>
			<!-- Common options-->
			<li class="opt">-a <span>&lt;arch&gt;</span></li>
			<li>Architecture du processeur (x64/i686)</li>
			<li class="opt">-n <span>&lt;net_pref&gt;</span></li>
			<li>Au choix: dhcpcd/dhcpcd@&lt;inet_addr&gt;,nm/networmanager<br>
			Utilisation de NetworkManager ou dhcpcd sur toutes les interfaces ou avec l'interface &lt;inet_addr&gt;</li>
			<li class="opt">-g <span>&lt;gpu_drv&gt;</span></li>
			<li>Pilote carte graphique parmi intel,nouveau,radeon/ati,virtualbox/vb,nvidia/nvidia304/nvidia340,all ( all pour tout les 
pilotes)</li>
			<li class="opt">-e <span>&lt;desk_env&gt;</span></li>
			<li>Environnement de bureau parmi plasma,lxqt,xfce,lxde,mate,gnome</li>
			<li class="opt">-h <span>&lt;hostname&gt;</span></li>
			<li>Nom de la machine</li>
			<li class="opt">-u <span>&lt;username&gt;</span></li>
			<li>Login utilisateur</li>
			
			<!-- Langage/Location options-->
			<li class="opt">-k <span>&lt;kbd_conf&gt;</span></li>
			<li>Disposition du clavier en console</li>
			<li class="opt">-K <span>&lt;xkbd_conf&gt;</span></li>
			<li>Disposition du clavier sous X</li>
			<li class="opt">-z <span>&lt;Zone/SousZone&gt;</span></li>
			<li>Fuseau horaire &agrave; suivre</li>
			
			<!-- Advanced -->
			<li class="opt">-l <span>&lt;/dev/sdX&gt;</span></li>
			<li>Installe le chargeur de d&eacute;marrage grub sur le p&eacute;ripherique /dev/sdX.</li>
			<li class="opt"> -c <span>&lt;cache_paquets&gt;</span></li>
			<li>Utilisation des paquets contenu dans le dossier &lt;cache_paquets&gt;</li>
			
			<!-- Other (Printing, Bluetooth, usefull softwares)-->
			<li class="opt">-p</li>
			<li>Gestion imprimante ( cups )</li>
			<li class="opt">-H</li>
			<li>Gestion imprimante HP ( cups + hplip )</li>
			<li class="opt">-b</li>
			<li>Gestion du bluetooth ( bluez bluez-utils )</li>
			<li class="opt">-L</li>
			<li>Installation de libreoffice</li>
			<li class="opt">-T</li>
			<li>Installation de thunderbird</li>
			
			<li class="opt"><br />-t</li>
			<li>Test mode, commands are in /tmp/anarchi_command</li>
			<li class="opt">-h</li>
			<li>Print this help message</li>
		</ul>
		
		</li>
	</ul>
