# freetoaster
Script bash atti alla realizzazione di un semplice distributore di iso (cd/dvd e usb)

Lo script automatizza la generazione di cd/dvd e usb di immagini iso (Distro GNU/Linux) fornendo una interfaccia di selezione a caratteri semigrafici.
Per il funzionamento è sufficiente una installazione base di una qualunque distribuzione GNU/Linux (io ho utilizzato Debian).
Sono inoltre necessari i seguenti pacchetti:
* _wodim_:  per la gestione della masterizzazione;
* _dialog_: per la realizzazione dell'interfaccia di selezione;
* _dd_: per masterizzare su device USB;
* _pv_: per ottenere a video un feedback del comando dd.

Lo script **writeiso.sh** usa dei file di testo per la definizione degli elenchi di iso tra cui scegliere.

Lo script **loadinfo.sh** aiuta nella generazione dei file di testo utilizzati da **writeiso.sh**.

E' stato aggiunta la possibilità di eseguire la masterizzazione anche con il software di masterizzazione con interfaccia grafica **xfburn**. In questo caso deve essere attivo il server X e deve essere installato il software xfburn.

