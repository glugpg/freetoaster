#!/bin/bash

std_dev="1"
std_speed="48"
f_listiso="listiso.info"
f_listdistro="distro.info"

# imposta il masterizzatore se passato come parametro
if [ $# -eq 0 ]; then
    dev_id=$std_dev
else
    dev_id=$1
fi
# device di masterizzazione
dev_disk=`wodim --devices | grep dev | cut -d "'" -f 2 | head -n $dev_id | tail -n 1`
# velocita' di masterizzazione
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
    # carica le info della distribuzione selezionata da file 
    for counter in $(seq 0 $((${#dist_path[@]} - 1)))
    do
        dist_id="000"$(($counter + 1))
        if [ "$1" == "${dist_id: -2}" ]; then
            f_path=${dist_path[$counter]}
            source "$f_path/$f_listiso"
            list_desc=("${iso_desc[@]:0}")
            list_iso=("${iso_file[@]:0}")
            list_title=${dist_title[$counter]}
        fi
    done
    # crea il menu di selezione delle iso
    echo     "    dialog --menu \\" >>"$f_source"
    echo     "       \"$list_title\\nSeleziona l'immagine da masterizzare:\" \\" >>"$f_source"
    echo     "       0 0 0 \\" >>"$f_source"
    # elenca tutte le opzioni dal relativo array delle iso
    for counter in $(seq 0 $((${#list_iso[@]} - 1)))
    do
        list_id="000"$(($counter + 1))
        echo "       \"${list_id: -2}\" \"${list_desc[$counter]}\" \\" >>"$f_source"
    done
    echo     "    2>\"$f_result\"" >>"$f_source"
    echo     "    exit_val=\"\$?\"" >>"$f_source"
    echo     "    if [ \"\$exit_val\" == \"0\" ] ; then" >>"$f_source"
    echo     "        ret_val=\`cat \"$f_result\"\`" >>"$f_source"
    echo     "        case \"\$ret_val\" in" >>"$f_source"
    # verifica l'iso selezionata
    for counter in $(seq 0 $((${#list_iso[@]} - 1)))
    do
        list_id="000"$(($counter + 1))
        echo "        \"${list_id: -2}\")" >>"$f_source"
        echo "            f_dist=\"\$f_path/\${list_iso[$counter]}\"" >>"$f_source"
        echo "            ;;" >>"$f_source"
    done
    echo     "        esac" >>"$f_source"
    echo     "    else" >>"$f_source"
    echo     "        ret_val=\"\"" >>"$f_source"
    echo     "    fi" >>"$f_source"

    source "$f_source"
    tmp_clean
} 

#---------------------------------------------------------------------------------------------------------
# Main procedure

source "$f_listdistro"
# inizia il ciclo infinito per la selezione della distribuzione
loop_val="0"
while [ "$loop_val" == "0" ]
do 
    # seleziona la distribuzione
    tmp_clean
    # crea il menu di selezione
    echo     "    dialog --menu \\" >>"$f_source"
    echo     "       \"Elenco delle distribuzioni disponibili per la masterizzazione:\" \\" >>"$f_source"
    echo     "       0 0 0 \\" >>"$f_source"
    # elenca tutte le opzioni dal relativo array
    for counter in $(seq 0 $((${#dist_path[@]} - 1)))
    do
        dist_id="000"$(($counter + 1))
        echo "       \"${dist_id: -2}\" \"${dist_desc[$counter]}\" \\" >>"$f_source"
    done
    echo     "    2>\"$f_result\"" >>"$f_source"
    echo     "    exit_val=\"\$?\"" >>"$f_source"
    echo     "    if [ \"\$exit_val\" == \"0\" ] ; then" >>"$f_source"
    echo     "        ret_val=\`cat \"$f_result\"\`" >>"$f_source"
    echo     "        loop_val=\"0\"" >>"$f_source"
    echo     "    else" >>"$f_source"
    echo     "        ret_val=\"\"" >>"$f_source"
    echo     "        loop_val=\"1\"" >>"$f_source"
    echo     "    fi" >>"$f_source"

    source "$f_source"
    tmp_clean

    # imposta la masterizzazione
    if [ "$loop_val" == "0" ] ; then
        f_dist=""
        # seleziona l'immagine da masterizzare
        select_distro "$ret_val" 
        if [ "$f_dist" != "" ] ; then
            dialog  --yesno \
                "Inserisci il nuovo cd/dvd nel masterizzatore, quindi premi <Si> per iniziare la copia di:\n\n   $f_dist" \
                0 0
            exit_val="$?"
            if [ "$exit_val" == "0" ] ; then
                # esegue la masterizzazione del cd
                wodim -v -eject speed="$speed" fs=16m gracetime=0 driveropts=burnfree dev="$dev_disk" -data -nopad "$f_dist"
                read
                exit_val="$?"
                if [[ "$exit_val" == "0" ]] ; then
                    dialog --msgbox "Copia terminata con successo $f_dist. ($exit_val)" 6 34
                else
                    dialog --msgbox "Peccato,  non c'e l'ho fatta. ($exit_val)" 6 34
                fi
            fi
        fi
    fi
    ret_val=""
done

exit 0
