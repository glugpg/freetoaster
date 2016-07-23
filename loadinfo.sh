#!/bin/bash

header_distro1="# ELENCO DELLE DISTRIBUZIONI"
header_distro2="# N.B. il file deve terminare con una riga vuota"
header_distro3="#"
header_distro4="# nome distro  | descrizione"
header_distro5="# ------------------------------------------------------"

descri_distro="...descrizione distribuzione..."

header_iso1="# ELENCO DELLE ISO ..."
header_iso2="# N.B. il file deve terminare con una riga vuota"
header_iso3="#"
header_iso4="# nome iso    | descrizione"
header_iso5="# ---------------------------------------------------------"

descri_iso="...descrizione iso..."

f_listiso="listiso.info"    # file con la list delle iso per una distribuzione
f_listdistro="distro.info"  # file con la lista delle tipologie di distribuzioni
ext_tmp=".tmp"
ext_old="~"

type_iso="iso"
type_distro="distro"

array_sep="|"

write_file=0
header_file=0
infotype=$type_distro

function remove_tmp()
{
    if [ $1 -eq 1 ]; then
        if [ -e "$2$ext_tmp" ]; then
            rm "$2$ext_tmp"
        fi
    fi
}

function rename_tmp()
{
    if [ $1 -eq 1 ]; then
        if [ -e "$2$ext_old" ]; then
            rm "$2$ext_old"
        fi
        if [ -e "$2" ]; then
            mv "$2" "$2$ext_old"
        fi
        if [ -e "$2$ext_tmp" ]; then
            mv "$2$ext_tmp" "$2"
        fi
    fi
}

function print_row()
{
    pad=$(printf '%0.1s' " "{1..80})
    padlength=16

    if [ $1 -eq 1 ]; then
        printf '%s' "$3" >> "$2$ext_tmp"
        printf '%*.*s' 0 $((padlength - ${#3} - ${#array_sep} )) "$pad" >> "$2$ext_tmp"
        printf '%s\n' "$array_sep $4" >> "$2$ext_tmp"
    else
        printf '%s' "$3"
        printf '%*.*s' 0 $((padlength - ${#3} - ${#array_sep} )) "$pad"
        printf '%s\n' "$array_sep $4"
    fi
}


# legge i parametri passati allo script
while getopts "hil:t:w" params
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
            echo    "     -w        rigenera il file con le informazioni"
            echo
            exit 0
            ;;
        i)
            header_file=1
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
        w)
            write_file=1
    esac
done

# primo parametro passato 'lista distribuzioni'
if [ $infotype == $type_distro ]; then

    remove_tmp $write_file "$f_listdistro"

    if [ $header_file -eq 1 ]; then
        if [ $write_file -eq 1 ]; then
            echo "$header_distro1" >> "$f_listdistro$ext_tmp"
            echo "$header_distro2" >> "$f_listdistro$ext_tmp"
            echo "$header_distro3" >> "$f_listdistro$ext_tmp"
        else
            echo "$header_distro1"
            echo "$header_distro2"
            echo "$header_distro3"
        fi
        name_element=$(echo "$header_distro4" | cut -d $array_sep -f 1 | sed -e 's/^\ //')
        descri_element=$(echo "$header_distro4" | cut -d $array_sep -f 2 | sed -e 's/^\ //')
        print_row $write_file "$f_listdistro" "$name_element" "$descri_element"
        if [ $write_file -eq 1 ]; then
            echo "$header_distro5" >> "$f_listdistro$ext_tmp"
        else
            echo "$header_distro5"
        fi
    fi

    for element in $(ls -d */ | sed -e 's/\/$//')
    do
        if [ -e "$f_listdistro" ]; then
            this_element=$(grep -e "^$element" "$f_listdistro")
            if [ -z "$this_element" ]; then
                print_row $write_file "$f_listdistro" "$element" "$descri_distro"
            else
                name_element=$(echo "$this_element" | cut -d $array_sep -f 1 | sed -e 's/^\ //')
                descri_element=$(echo "$this_element" | cut -d $array_sep -f 2 | sed -e 's/^\ //')
                print_row $write_file "$f_listdistro" "$name_element" "$descri_element"
            fi
        else
            print_row $write_file "$f_listdistro" "$element" "$descri_distro"
        fi
    done

    rename_tmp $write_file "$f_listdistro"

# primo parametro passato 'lista iso'
else

    remove_tmp $write_file "$f_listiso"

    if [ $header_file -eq 1 ]; then
        if [ $write_file -eq 1 ]; then
            echo "$header_iso1" >> "$f_listiso$ext_tmp"
            echo "$header_iso2" >> "$f_listiso$ext_tmp"
            echo "$header_iso3" >> "$f_listiso$ext_tmp"
        else
            echo "$header_iso1"
            echo "$header_iso2"
            echo "$header_iso3"
        fi
        name_element=$(echo "$header_iso4" | cut -d $array_sep -f 1 | sed -e 's/^\ //')
        descri_element=$(echo "$header_iso4" | cut -d $array_sep -f 2 | sed -e 's/^\ //')
        print_row $write_file "$f_listiso" "$name_element" "$descri_element"
        if [ $write_file -eq 1 ]; then
            echo "$header_iso5" >> "$f_listiso$ext_tmp"
        else
            echo "$header_iso5"
        fi
    fi

    for element in $(ls | grep ".iso$")
    do
        if [ -e "$f_listiso" ]; then
            this_element=$(grep -e "^$element" "$f_listiso")
            if [ -z "$this_element" ]; then
                print_row $write_file "$f_listiso" "$element" "$descri_iso"
            else
                name_element=$(echo "$this_element" | cut -d $array_sep -f 1 | sed -e 's/^\ //')
                descri_element=$(echo "$this_element" | cut -d $array_sep -f 2 | sed -e 's/^\ //')
                print_row $write_file "$f_listiso" "$name_element" "$descri_element"
            fi
        else
            print_row $write_file "$f_listiso" "$element" "$descri_iso"
        fi
    done

    rename_tmp $write_file "$f_listiso"

fi
