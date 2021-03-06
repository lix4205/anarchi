#!/bin/bash

# DIR_SCRIPT=/media/srv/scripts/anarchic

NAME_SOFT="anarchi"
NAME_APP="${NAME_SOFT^}"
DIR_SCRIPT="$( dirname $0 )/.."

echo $DIR_SCRIPT
# exit
DIR_TMP=/tmp
ARCHIVE_NAME="$NAME_APP-$( date -I | sed  "s/-//g" ).tar.gz"
VERSION=1.0

# On copie les fichiers dont on a besoin...
mkdir $DIR_TMP/$NAME_APP
cp -R $DIR_SCRIPT/{files,launchInstall.sh,pacinstall.sh,Lisez-moi.txt,tool/open_editor.sh} $DIR_TMP/$NAME_APP/

cd $DIR_TMP
# On initialise le fichier custom_user ( bah ouais j'ai des trucs persos... )
mv $NAME_APP/files/custom_all $NAME_APP/files/custom_user
# On créé l'archive
tar zcf $ARCHIVE_NAME $NAME_APP/
if [ ! -e $DIR_SCRIPT/$ARCHIVE_NAME ]; then
	mv $ARCHIVE_NAME $DIR_SCRIPT
else
	echo "==> $DIR_SCRIPT/$ARCHIVE_NAME existe déjà !
	-> $ARCHIVE_NAME est dispnible dans $DIR_TMP"
fi
rm -R $DIR_TMP/$NAME_APP
