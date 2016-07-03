#!/bin/bash

std_speed="48"
program_name="xfburn"
f_listiso="listiso.info"
f_listdistro="distro.info"

dev_id="1"
use_alternative="0"

# legge i parametri passati allo script
while getopts "ai:" params
do
    case "$params" in
        i)
            if [ -n "$OPTARG" ]; then
                dev_id="$OPTARG"
            else
                dev_id ="1"
            fi
            ;;
        a)
            use_alternative="1"
            ;;
    esac
done

# interroga il sistema per conoscere qual'è il device su cui masterizzazione
dev_disk=`wodim dev=/dev/sr0 --devices | grep dev | cut -d "'" -f 2 | head -n $dev_id | tail -n 1`
# imposta la velocita' di masterizzazione
speed=$std_speed
# variabili usate per la selezione della distribuzione
f_source=`whoami`"_menu.sh"
f_result=`whoami`"_result.tmp"
loop_val=""
f_dist=""
f_path=""
ret_val=""
exit_val=""

function tmp_clean {
    # svuota i file temporanei utilizzati dallo script
    if [ -e "$f_result" ] ; then
        rm "$f_result"  
    fi
    if [ -e "$f_source" ] ; then
        rm "$f_source"  
    fi
}

function select_distro
{
    tmp_clean
    list_title=""
    # carica le info per il tipo di distribuzione passata come parametro
    for counter in $(seq 0 $((${#distro[@]} - 1)))
    do
        dist_id="000"$(($counter + 1))
        if [ "$1" -eq "${dist_id: -2}" ]; then
            f_path=`echo ${distro[$counter]} | cut -d "|" -f 2 | sed -e "s/^[[:blank:]]*//" | sed -e "s/[[:blank:]]*$//"`
            # verifica che la cartella della tipologia di distribuzione esista
            if [ -e "$f_path/$f_listiso" ]; then
                source "$f_path/$f_listiso"
                list_title=`echo ${distro[$counter]} | cut -d "|" -f 1 | sed -e "s/^[[:blank:]]*//" | sed -e "s/[[:blank:]]*$//" | tr '[:lower:]' '[:upper:]'`
            else
                list_title=""
            fi
        fi
    done

    # solo se è stato caricato l'elenco delle distro
    if [ ! -z "$list_title" ]; then
        # crea lo script menu di selezione delle distro
        echo     "    dialog --menu \\" >>"$f_source"
        echo     "       \"$list_title\\nSeleziona l'immagine da masterizzare:\" \\" >>"$f_source"
        echo     "       0 0 0 \\" >>"$f_source"
        # scrive nello script menu la lista delle distro su cui fare la selezione
        for counter in $(seq 0 $((${#iso[@]} - 1)))
        do
            list_id="000"$(($counter + 1))
            list_desc=`echo ${iso[$counter]} | cut -d "|" -f 1 | sed -e "s/^[[:blank:]]*//" | sed -e "s/[[:blank:]]*$//"`
            echo "       \"${list_id: -2}\" \"$list_desc\" \\" >>"$f_source"
        done
        echo     "    2>\"$f_result\"" >>"$f_source"
        echo     "    exit_val=\"\$?\"" >>"$f_source"
        echo     "    if [ \"\$exit_val\" -eq \"0\" ] ; then" >>"$f_source"
        echo     "        ret_val=\`cat \"$f_result\"\`" >>"$f_source"
        echo     "        case \"\$ret_val\" in" >>"$f_source"
        # scrive nello script menu la "case" per individuare la distro selezionata
        for counter in $(seq 0 $((${#iso[@]} - 1)))
        do
            list_id="000"$(($counter + 1))
            list_iso=`echo ${iso[$counter]} | cut -d "|" -f 2 | sed -e "s/^[[:blank:]]*//" | sed -e "s/[[:blank:]]*$//"`
            iso_item="$f_path/$list_iso"
            echo "        \"${list_id: -2}\")" >>"$f_source"
            echo "            f_dist=$iso_item" >>"$f_source"
            echo "            ;;" >>"$f_source"
        done
        echo     "        esac" >>"$f_source"
        echo     "    else" >>"$f_source"
        echo     "        ret_val=\"\"" >>"$f_source"
        echo     "    fi" >>"$f_source"

        # esegue lo script menu per selezionare la distro
        source "$f_source"
    fi
    tmp_clean
} 

#---------------------------------------------------------------------------------------------------------
# Main procedure

source "$f_listdistro"
# inizia il ciclo infinito per la selezione della distribuzione
loop_val="0"
while [ "$loop_val" -eq "0" ]
do 
    # seleziona la distribuzione
    tmp_clean
    # crea lo script menu di selezione delle tipologie di distribuzione
    echo     "    dialog --menu \\" >>"$f_source"
    echo     "       \"Elenco delle distribuzioni disponibili per la masterizzazione:\" \\" >>"$f_source"
    echo     "       0 0 0 \\" >>"$f_source"
    # scrive nello script menu la lista delle tipologie su cui fare la selezione
    for counter in $(seq 0 $((${#distro[@]} - 1)))
    do
        dist_id="000"$(($counter + 1))
        dist_desc=`echo ${distro[$counter]} | cut -d "|" -f 1 | sed -e "s/^[[:blank:]]*//" | sed -e "s/[[:blank:]]*$//"`
        echo "       \"${dist_id: -2}\" \"$dist_desc\" \\" >>"$f_source"
    done
    echo     "    2>\"$f_result\"" >>"$f_source"
    echo     "    exit_val=\"\$?\"" >>"$f_source"
    echo     "    if [ \"\$exit_val\" -eq \"0\" ] ; then" >>"$f_source"
    echo     "        ret_val=\`cat \"$f_result\"\`" >>"$f_source"
    echo     "        loop_val=\"0\"" >>"$f_source"
    echo     "    else" >>"$f_source"
    echo     "        ret_val=\"\"" >>"$f_source"
    echo     "        loop_val=\"1\"" >>"$f_source"
    echo     "    fi" >>"$f_source"

    # esegue lo script menu per la selezione delle tipologie di distribuzione
    source "$f_source"
    tmp_clean

    # imposta la masterizzazione
    if [ "$loop_val" -eq "0" ] ; then
        f_dist=""
        # chiamata alla funzione per la selezione della distribuzione
        select_distro "$ret_val" 
        if [ ! -z "$f_dist" ] ; then
            # chiede conferma per la masterizzazione della distro selezionata
            dialog  --yesno \
                "Inserisci il nuovo cd/dvd nel masterizzatore, quindi premi <Si> per iniziare la copia di:\n\n   $f_dist" \
                0 0
            exit_val="$?"
            if [ "$exit_val" -eq "0" ] ; then
                if [ $use_alternative -eq "0" ]; then
                    # esegue la masterizzazione del cd
                    wodim -v -eject speed="$speed" fs=16m gracetime=0 driveropts=burnfree dev="$dev_disk" -data -nopad "$f_dist"
                    read
                    exit_val="$?"
                    if [[ "$exit_val" -eq "0" ]] ; then
                        dialog --msgbox "Copia terminata con successo $f_dist. ($exit_val)" 6 34
                    else
                        dialog --msgbox "Peccato,  non c'e l'ho fatta. ($exit_val)" 6 34
                    fi
                else
                    # verifica presenza xfburn nel sistema
                    alternative_path=`which $program_name`
                    if [ -n "$alternative_path" ]; then
                        $program_name -i "$f_dist" 2> /dev/null
                    else
                        dialog --msgbox "Comando $program_name non presente nel sistema." 6 34
                    fi
                fi
            fi
        fi
    fi
    ret_val=""
done

exit 0
