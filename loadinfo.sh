#!/bin/bash

header_distro1="# ELENCO DELLE DISTRIBUZIONI"
header_distro2="# N.B. il file deve terminare con una riga vuota"
header_distro3="#"
header_distro4="# nome distro  | descrizione"

descri_distro="...descrizione distribuzione..."

header_iso1="# ELENCO DELLE ISO -"
header_iso2="# N.B. il file deve terminare con una riga vuota"
header_iso3="#"
header_iso4="# nome iso    | descrizione"

distro_name=""
descri_iso="...descrizione iso..."

f_listiso="listiso.info"    # file con la list delle iso per una distribuzione
f_listdistro="distro.info"  # file con la lista delle tipologie di distribuzioni

ext_tmp=".tmp"              # estensione del file delle info durante la riscrittura
ext_old="~"                 # estensione del file delle info a seguito della riscrittura

type_iso="iso"              # parametro per recuperare le informazioni delle iso
type_distro="distro"        # parametro per recuperare le informazioni delle distribuzioni

array_sep="|"               # carattere di separazione delle colonne

row_len=60                  # lunghezza di una riga di informazioni
fcol_len=16                 # lunghezza della prima colonna delle informazioni

# imposta la rigenerazione del file delle informazioni
write_file=0

# imposta la generazione delle righe di intestazione
header_file=0

# imposta il tipo predefinito di informazioni da recuperare
infotype=$type_distro

# legge i parametri passati allo script
while getopts "f:hil:t:w" params
do
    case "$params" in
        f)
            if [ -n "$OPTARG" ]; then
                fcol_len="$OPTARG"
            fi
            ;;
        h)
            echo
            echo    "Uso: ${0##*/} [-hilt:]"
            echo    "     Mostra la lista delle distribuzioni(directories)"
            echo    "     oppure delle ISO (file *.iso) presenti nella "
            echo    "     directory corrente"
            echo 
            echo    "     -f LENGTH larghezza della prima colonna della lista"
            echo    "     -h        mostra queste informazioni ed esce"
            echo    "     -i        crea un nuovo file"
            echo    "     -l LENGTH larghezza totale della colonna della lista"
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
                row_len="$OPTARG"
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
            ;;
    esac
done

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

function print_info()
{
    pad=$(printf '%0.1s' " "{1..80})

    if [ $1 -eq 1 ]; then
        printf '%s' "$3" >> "$2$ext_tmp"
        printf '%*.*s' 0 $((fcol_len - ${#3} - ${#array_sep} )) "$pad" >> "$2$ext_tmp"
        printf '%s\n' "$array_sep $4" >> "$2$ext_tmp"
    else
        printf '%s' "$3"
        printf '%*.*s' 0 $((fcol_len - ${#3} - ${#array_sep} )) "$pad"
        printf '%s\n' "$array_sep $4"
    fi
}

#---------------------------------------------------------------------------------------------------------
# Main procedure

header_sep=$(eval printf '%0.1s' "-"{1..$row_len})

# primo parametro passato 'lista distribuzioni'
if [ $infotype == $type_distro ]; then

    # elimina il file temporaneo utilizzato per la
    # riscrittura del file delle informazioni
    remove_tmp $write_file "$f_listdistro"

    # inserisce le righe di intestazione
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
        # allinea la riga di intestazione che descrive il formato delle colonne
        name_element=$(echo "$header_distro4" | cut -d $array_sep -f 1 | sed -e 's/^\ //')
        descri_element=$(echo "$header_distro4" | cut -d $array_sep -f 2 | sed -e 's/^\ //')
        print_info $write_file "$f_listdistro" "$name_element" "$descri_element"
        if [ $write_file -eq 1 ]; then
            echo "$header_sep" >> "$f_listdistro$ext_tmp"
        else
            echo "$header_sep"
        fi
    fi

    # inserisce l'elenco delle distribuzioni (directories)
    for element in $(ls -d */ | sed -e 's/\/$//')
    do
        # verifica se l'elmenento (directory)
        # analizzto contieme immagini .iso
        iso_list=($(ls "$element" | grep ".iso$"))
        if [ ! -z $iso_list ]; then
            # verifica se l'elemento analizzato sia presente
            # nel precedente file dell informazioni
            if [ -e "$f_listdistro" ]; then
                this_element=$(grep -e "^$element" "$f_listdistro")
                if [ -z "$this_element" ]; then
                    # inserisce l'elemento analizzato
                    print_info $write_file "$f_listdistro" "$element" "$descri_distro"
                else
                    # inserisce l'elemento analizzato recuperandolo
                    # dal precedente file delle informazioni
                    name_element=$(echo "$this_element" | cut -d $array_sep -f 1 | sed -e 's/^\ //')
                    descri_element=$(echo "$this_element" | cut -d $array_sep -f 2 | sed -e 's/^\ //')
                    print_info $write_file "$f_listdistro" "$name_element" "$descri_element"
                fi
            else
                # inserisce la distribuzione
                print_info $write_file "$f_listdistro" "$element" "$descri_distro"
            fi
        fi
    done

    # riscrive il file delle informazioni e mantiene
    # il precedente file in formato backup
    rename_tmp $write_file "$f_listdistro"

# primo parametro passato 'lista iso'
else
    # elimina il file temporaneo utilizzato per la
    # riscrittura del file delle informazioni
    remove_tmp $write_file "$f_listiso"

    distro_name=$(echo $(basename $(pwd)) | tr [:lower:] [:upper:])
    # inserisce le righe di intestazione
    if [ $header_file -eq 1 ]; then
        if [ $write_file -eq 1 ]; then
            echo "$header_iso1 $distro_name" >> "$f_listiso$ext_tmp"
            echo "$header_iso2" >> "$f_listiso$ext_tmp"
            echo "$header_iso3" >> "$f_listiso$ext_tmp"
        else
            echo "$header_iso1 $distro_name"
            echo "$header_iso2"
            echo "$header_iso3"
        fi
        # allinea la riga di intestazione che descrive il formato delle colonne
        name_element=$(echo "$header_iso4" | cut -d $array_sep -f 1 | sed -e 's/^\ //')
        descri_element=$(echo "$header_iso4" | cut -d $array_sep -f 2 | sed -e 's/^\ //')
        print_info $write_file "$f_listiso" "$name_element" "$descri_element"
        if [ $write_file -eq 1 ]; then
            echo "$header_sep" >> "$f_listiso$ext_tmp"
        else
            echo "$header_sep"
        fi
    fi

    # inserisce l'elenco delle iso
    for element in $(ls | grep ".iso$")
    do
        # verifica se l'elemento analizzato sia presente
        # nel precedente file dell informazioni
        if [ -e "$f_listiso" ]; then
            this_element=$(grep -e "^$element" "$f_listiso")
            if [ -z "$this_element" ]; then
                # inserisce l'elemento analizzato
                print_info $write_file "$f_listiso" "$element" "$descri_iso"
            else
                # inserisce l'elemento analizzato recuperandolo
                # dal precedente file delle informazioni
                name_element=$(echo "$this_element" | cut -d $array_sep -f 1 | sed -e 's/^\ //')
                descri_element=$(echo "$this_element" | cut -d $array_sep -f 2 | sed -e 's/^\ //')
                print_info $write_file "$f_listiso" "$name_element" "$descri_element"
            fi
        else
            # inserisce l'elemento analizzato
            print_info $write_file "$f_listiso" "$element" "$descri_iso"
        fi
    done

    # riscrive il file delle informazioni e mantiene
    # il precedente file in formato backup
    rename_tmp $write_file "$f_listiso"

fi

exit 0
