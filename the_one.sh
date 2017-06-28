#!
# Script permettant la mise a jour des emplacements de sauvegarde a actualiser
# Il doit permettre l'ajout de chaque champ renseigner dans le fichier source "save_file_list.txt" d'etre ajouté a la liste des fichiers a scanner pour modification dans le save_steam.path

# Le script suivant permet l'ajout d'une syntaxe dans le fichier path de systemd afin de scanner le repertoire en question

# Definition des variables
liste="/home/moonls/CloudStation/script/test/save_file_list.txt"
SteamPath="/home/moonls/CloudStation/script/test/save_steam.path"
Save_Steam="/home/moonls/CloudStation/script/save_steam.sh"
InputTemp="/home/moonls/CloudStation/script/test/input_temp"
liste_path="/home/moonls/CloudStation/script/test/liste_path"
liste_source="/home/moonls/CloudStation/script/test/liste_source"
AjoutTemp="/home/moonls/CloudStation/script/test/ajout_temp"
log="/home/moonls/CloudStation/script/test/log"
locPRF="/home/moonls/CloudStation/script/test/"
Syno="/home/moonls/CloudStation/script/test/0rsync"
nom=
chemin=
verif_save_steam=
notif_icon="/home/moonls/script/notification_icon"
test_steam=

# Fonction
# Cette fonction permet l'ajout dans le script save_steam.sh de l'ajout des nouveaux noms
function ajout_script
{
echo ""
echo "#Sauvegarde de $nom
echo -e \$chrono >>\$logfile
echo -e \"\n------------- $nom -------------\n\" >>\$logfile
unison -batch save_steam_$nom >>\$logfile"
}

echo "============= $(date) ==============" >> $log


# PART 1 - Creation de fichier .prf
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Boucle de lecture de la liste "save_file_list.txt"
# assignation des variables nom et chemin
# on test si le fichier prf correspondant a la variable nom existe
# si il n'existe pas, on le crée sur la base du prf source "base_prf"

while IFS='=' read nom chemin
do
	if [ -f ""$locPRF""$nom".prf" ]
	then
		echo ""$nom".prf est deja existant" >> $log
	else
		cp "$locPRF"base_prf "$locPRF""$nom".prf
		sed -i -e s/\$nom/$nom/g "$locPRF""$nom".prf
	fi

	count=$(grep "#Sauvegarde de $nom" $Save_Steam | wc -l)	
	if [ "$count" -gt "0" ] 
	then
		echo "La sauvegarde est déjà présente dans le script save_steam.sh" >> $log
	else
		ajout_script >> $Save_Steam
		if [ -e $Syno/$nom ]
		then
			echo "Le repertoire $nom est deja existant sur le Synology" >> $log
		else
			echo "create dir $Syno $nom"
			mkdir $Syno/$nom
			echo "$nom a été créé sur le Syno" >> $log
			notify-send "SAUVEGARDE STEAM" \
			    "La sauvegarde $nom a été créée sur le Syno" \
			    -i $notif_icon/Warning.svg \
			    -t 10000
	fi
fi
done < $liste



#PART 2 - Ajout des sources dans le path et script
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Vérifie si toutes les entrées du fichier source save_file_list.txt sont présentes dans le fichier save_steam.path et génère un fichier d'ajout

# Pour cela on realise un awk sur le fichier path afin de récupérer les chemins à comparer a la variable "chemin" définie plus haut
# Il est nécessaire de faire un "sort" avant de comparer avec "comm" car l'option --nocheck-order ne fonctionne pas tres bien

awk -F "PathModified=" '{ print $2 }' $SteamPath | sort -bdf > $liste_path
awk -F "=" '{ print $2 }' $liste | sort -bdf > $liste_source
comm -32 --nocheck-order $liste_source $liste_path > $InputTemp

# On ajoute l'entete PathModified= devant chaque ligne d'ajout pour coller au modele du fichier path
sed 's/^/PathModified=/' $InputTemp > $InputTemp"2"

# insere un retour charriot a la fin du fichier pour l'insertion suivante pour assurer le retour charriot a l'insertion
sed -i -e '$a\' $InputTemp"2"

# on ecrase le fichier en effectuant un mv
mv $InputTemp"2" $InputTemp

# Permet d'inserer le fichier ajout avec sed
# On fait une recherche avec sed du champ [Path] et on ajoute la liste en générant un fichier temporaire
sed -e "/\[Path]/ r\
	        $InputTemp" $SteamPath > $AjoutTemp

# permet d'importer les modifications en effectuant un "mv" qui remplace la source
mv "$AjoutTemp" "$SteamPath"


# PART 3 - Relancer le daemon systemd
# Il faut ensuite recharger le fichier modifier pour la prise en compte dans systemd

systemctl --user daemon-reload

# On purge les fichiers restants inutiles
rm -f "$liste_path" "$liste_source"

notify-send "SAUVEGARDE STEAM" \
            "La sauvegarde est terminée" \
	    -i $notif_icon/Coche_ok_verte.svg \
	    -t 10000
exit 0
