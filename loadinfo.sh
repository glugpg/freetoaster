#!/bin/bash

header_distro="""
# ELENCO DELLE DISTRIBUZIONI
# N.B. il file deve terminare con una riga vuota
#
# nome distro  | descrizione
"""
descri_distro="...descrizione distribuzione..."

header_iso="""
# ELENCO DELLE ISO ...
# N.B. il file deve terminare con una riga vuota
#
# nome iso    | descrizione
"""
descri_iso="...descrizione iso..."

type_iso="iso"
type_distro="distro"
f_listiso="listiso.info"     # file con la list delle iso per una distribuzione

pad=$(printf '%0.1s' " "{1..80})
padlength=16
separator="|"

new_file=0
infotype=$type_distro

# legge i parametri passati allo script
while getopts "hil:t:" params
do
    case "$params" in
        h)
            echo
            echo    "Uso: ${0##*/} [-hilt:]"
            echo    "     Mostra la lista delle distribuzioni(directories)"
            echo    "     oppure delle ISO (file *.iso) presenti nella "
            echo    "     directory corrente"
            echo 
            echo    "     -h        mostra queste informazioni ed esce"
            echo    "     -i        crea un nuovo file"
            echo    "     -l LENGTH larghezza della prima colonna della lista"
            echo    "     -t TYPE   tipo di informazioni da visualizzare"
            echo    "                 $type_distro => lista delle distribuzioni"
            echo    "                 $type_iso    => lista delle iso"
            echo
            exit 0
            ;;
        i)
            new_file=1
            ;;
        l)
            if [ -n "$OPTARG" ]; then
                padlength="$OPTARG"
            fi
            ;;
        t)
            if [ -n "$OPTARG" ]; then
                infotype="$OPTARG"
            else
                infotype=$type_distro
            fi
            ;;
    esac
done

# primo parametro passato 'lista distribuzioni'
if [ $infotype == $type_distro ]; then
	if [ $new_file -eq 1 ]; then
    	echo "$header_distro"
    fi
    for element in $(ls -d */ | sed -e 's/\/$//')
    do
        printf '%s' "$element"
        printf '%*.*s' 0 $((padlength - ${#element} - ${#separator} )) "$pad"
        printf '%s\n' "$separator $descri_distro"
    done
# primo parametro passato 'lista iso'
else
	if [ $new_file -eq 1 ]; then
	    echo "$header_iso"
	fi

	for element in $(ls | grep ".iso$")
	do
		if [ -e "$f_listiso" ]; then
			row_founded=$(grep $element $f_listiso)
		if [ -z "$row_founded" ]; then
			printf '%s' "$element"
			printf '%*.*s' 0 $((padlength - ${#element} - ${#separator} )) "$pad"
			printf '%s\n' "$separator $descri_iso"
		else
			echo $row_founded
		fi
	else
      printf '%s' "$element"
      printf '%*.*s' 0 $((padlength - ${#element} - ${#separator} )) "$pad"
      printf '%s\n' "$separator $descri_iso"
    fi
  done
fi
