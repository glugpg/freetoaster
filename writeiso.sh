#!/bin/bash

# variabili usate per la gestione dei menu di scelta dinamici
f_source_menu=`whoami`"_menu.sh"
f_result=`whoami`"_result.tmp"

# variabili predefinite per il funzionamento dello script
dev_id="1"                   # indice del masterizzatore da utilizzare
std_speed="48"               # speed per la masterizzazione CD/DVD
program_name="xfburn"        # software alternativo per la masterizzazione CD/DVD
f_listiso="listiso.info"     # file con la list delle iso per una distribuzione
f_listdistro="distro.info"   # file con la lista delle tipologie di distribuzioni
use_alternative="0"          # flag per l'uso del software di masterizzazione alternativo

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

# resetta le variabili di scelta 
f_path=""
f_dist=""
f_usbdev=""

# resetta le varibili di uscita dai menu di scelta
ret_val=""
exit_val=""

# resetta la variabile di gestione del "ciclo infinito" dello script
loop_val=""

function tmp_clean {
    # svuota i file temporanei utilizzati dallo script
    if [ -e "$f_result" ] ; then
        rm "$f_result"
    fi
    if [ -e "$f_source_menu" ] ; then
        rm "$f_source_menu"
    fi
}

function select_iso
{
    tmp_clean

    f_path=""
    f_dist=""
    list_title=""

    # carica la lista delle iso del tipo di distribuzione passata come parametro
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
    # verifica che sia stato caricato l'elenco delle iso
    if [ ! -z "$list_title" ]; then
        # crea lo script menu di selezione delle iso
        echo     "    dialog --menu \\" >>"$f_source_menu"
        echo     "       \"$list_title\\nSeleziona l'immagine da masterizzare:\" \\" >>"$f_source_menu"
        echo     "       0 0 0 \\" >>"$f_source_menu"
        # scrive nello script menu la lista delle iso da cui fselezionare
        for counter in $(seq 0 $((${#iso[@]} - 1)))
        do
            list_id="000"$(($counter + 1))
            list_desc=`echo ${iso[$counter]} | cut -d "|" -f 1 | sed -e "s/^[[:blank:]]*//" | sed -e "s/[[:blank:]]*$//"`
            echo "       \"${list_id: -2}\" \"$list_desc\" \\" >>"$f_source_menu"
        done
        echo     "    2>\"$f_result\"" >>"$f_source_menu"
        echo     "    exit_val=\"\$?\"" >>"$f_source_menu"
        echo     "    if [ \"\$exit_val\" -eq \"0\" ] ; then" >>"$f_source_menu"
        echo     "        ret_val=\`cat \"$f_result\"\`" >>"$f_source_menu"
        echo     "        case \"\$ret_val\" in" >>"$f_source_menu"
        # scrive nello script menu la "case" per individuare la iso selezionata
        for counter in $(seq 0 $((${#iso[@]} - 1)))
        do
            list_id="000"$(($counter + 1))
            list_iso=`echo ${iso[$counter]} | cut -d "|" -f 2 | sed -e "s/^[[:blank:]]*//" | sed -e "s/[[:blank:]]*$//"`
            iso_item="$f_path/$list_iso"
            echo "        \"${list_id: -2}\")" >>"$f_source_menu"
            echo "            f_dist=$iso_item" >>"$f_source_menu"
            echo "            ;;" >>"$f_source_menu"
        done
        echo     "        esac" >>"$f_source_menu"
        echo     "    else" >>"$f_source_menu"
        echo     "        ret_val=\"\"" >>"$f_source_menu"
        echo     "    fi" >>"$f_source_menu"
        # esegue lo script menu per selezionare la iso
        source "$f_source_menu"
    fi

    tmp_clean
} 

function select_usbdevice {
    tmp_clean

    f_usbdev=""

    # carica la lista di device USB dal sistema da cui selezionare
    usb_list=($(grep -Hv ^0$ /sys/block/*/removable | grep sd | cut -d"/" -f 4))
    # crea lo script menu di selezione del device USB
    echo     "    dialog --menu \\" >> "$f_source_menu"
    echo     "       \"Elenco dei device USB:\" \\" >>"$f_source_menu"
    echo     "       0 0 0 \\" >>"$f_source_menu"
    for counter in $(seq 0 $((${#usb_list[@]} - 1)))
    do
        usb_id="000"$(($counter + 1))
        usb_model=`less /sys/block/${usb_list[$counter]}/device/model`
        echo "       \"${usb_id: -2}\" \"$usb_model (${usb_list[$counter]})\" \\" >>"$f_source_menu"
    done
    echo     "    2>\"$f_result\"" >>"$f_source_menu"
    echo     "    exit_val=\"\$?\"" >>"$f_source_menu"
    echo     "    if [ \"\$exit_val\" -eq \"0\" ] ; then" >>"$f_source_menu"
    echo     "        ret_val=\`cat \"$f_result\"\`" >>"$f_source_menu"
    echo     "        case \"\$ret_val\" in" >>"$f_source_menu"
    # scrive nello script menu la "case" per individuare il device USB selezionato
    for counter in $(seq 0 $((${#usb_list[@]} - 1)))
    do
        usb_id="000"$(($counter + 1))
        usb_device=/dev/${usb_list[$counter]}
        echo "        \"${usb_id: -2}\")" >>"$f_source_menu"
        echo "            f_usbdev=$usb_device" >>"$f_source_menu"
        echo "            ;;" >>"$f_source_menu"
    done
    echo     "        esac" >>"$f_source_menu"
    echo     "    else" >>"$f_source_menu"
    echo     "        ret_val=\"\"" >>"$f_source_menu"
    echo     "    fi" >>"$f_source_menu"
    # esegue lo script menu per la selezione delle tipologie di distribuzione
    source "$f_source_menu"

    tmp_clean
}

#---------------------------------------------------------------------------------------------------------
# Main procedure

# carica la lista delle tipologia di distribuzione
source "$f_listdistro"
# inizia il ciclo infinito per la selezione della distribuzione
loop_val="0"
while [ "$loop_val" -eq "0" ]
do 
    # seleziona la distribuzione
    tmp_clean

    # crea lo script menu di selezione delle tipologie di distribuzione
    echo     "    dialog --menu \\" >>"$f_source_menu"
    echo     "       \"Elenco delle distribuzioni disponibili per la masterizzazione:\" \\" >>"$f_source_menu"
    echo     "       0 0 0 \\" >>"$f_source_menu"
    # scrive nello script menu la lista delle tipologie da cui selezionare
    for counter in $(seq 0 $((${#distro[@]} - 1)))
    do
        dist_id="000"$(($counter + 1))
        dist_desc=`echo ${distro[$counter]} | cut -d "|" -f 1 | sed -e "s/^[[:blank:]]*//" | sed -e "s/[[:blank:]]*$//"`
        echo "       \"${dist_id: -2}\" \"$dist_desc\" \\" >>"$f_source_menu"
    done
    echo     "    2>\"$f_result\"" >>"$f_source_menu"
    echo     "    exit_val=\"\$?\"" >>"$f_source_menu"
    echo     "    if [ \"\$exit_val\" -eq \"0\" ] ; then" >>"$f_source_menu"
    echo     "        ret_val=\`cat \"$f_result\"\`" >>"$f_source_menu"
    echo     "        loop_val=\"0\"" >>"$f_source_menu"
    echo     "    else" >>"$f_source_menu"
    echo     "        ret_val=\"\"" >>"$f_source_menu"
    echo     "        loop_val=\"1\"" >>"$f_source_menu"
    echo     "    fi" >>"$f_source_menu"
    # esegue lo script menu per la selezione delle tipologie di distribuzione
    source "$f_source_menu"

    tmp_clean

    # verifica se selezionata una tipologia di distribuzione
    if [ "$loop_val" -eq "0" ]; then
        # esegue la funzione per la selezione della iso
        select_iso "$ret_val" 
        if [ ! -z "$f_dist" ]; then
            # sceglie se masterizzare un CD/DVD o un device USB
            dialog --menu "Seleziona destinazione" 0 0 0 "01" "CD/DVD" "02" "USB DEVICE" 2>"$f_result"
            if [ $? -eq 0 ]; then
                ret_val=`cat "$f_result"`
                # masterizzare un CD/DVD
                if [ $ret_val -eq "01" ]; then
                    # chiede conferma per la masterizzazione della iso selezionata
                    dialog  --yesno \
                        "Inserisci il nuovo cd/dvd nel masterizzatore, quindi premi <Si> per iniziare la copia di:\n\n   $f_dist" \
                        0 0
                    exit_val="$?"
                    if [ "$exit_val" -eq "0" ] ; then
                        # verifica se utilizzare WODIM oppure XFBURN
                        if [ $use_alternative -eq "0" ]; then
                            # esegue la masterizzazione del cd con WODIM
                            wodim -v -eject speed="$speed" fs=16m gracetime=0 driveropts=burnfree dev="$dev_disk" -data -nopad "$f_dist"
                            exit_val="$?"
                            read
                            if [[ "$exit_val" -eq "0" ]] ; then
                                dialog --msgbox "Copia terminata con successo $f_dist. ($exit_val)" 6 34
                            else
                                dialog --msgbox "Peccato,  non c'e l'ho fatta. ($exit_val)" 6 34
                            fi
                        else
                            # esegue la masterizzazione del cd con XFBURN
                            alternative_path=`which $program_name`
                            # verifica presenza xfburn nel sistema
                            if [ -n "$alternative_path" ]; then
                                $program_name -i "$f_dist" 2> /dev/null
                            else
                                dialog --msgbox "Comando $program_name non presente nel sistema." 6 34
                            fi
                        fi
                    fi
                # masterizzare un device USB
                else
                    # esegue la funzione per la selezione del device USB
                    select_usbdevice
                    if [ ! -z "$f_usbdev" ]; then
                        dd if=$f_dist of=$f_usbdev bs=4M
                        exit_val="$?"
                        read
                        if [[ "$exit_val" -eq "0" ]] ; then
                            dialog --msgbox "Copia terminata con successo $f_dist. ($exit_val)" 6 34
                        else
                            dialog --msgbox "Peccato,  non c'e l'ho fatta. ($exit_val)" 6 34
                        fi
                    fi
                fi
            else
                ret_val=""
            fi
        fi
    fi
    ret_val=""
done

exit 0
