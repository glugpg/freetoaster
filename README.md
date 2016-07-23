# freetoaster
Script bash utile per la realizzazione di un distributore di iso (cd/dvd e usb)

Lo script automatizza la generazione di cd/dvd e usb di immagini iso (Distro GNU/Linux) fornendo una interfaccia di selezione a caratteri semigrafici.
Per il funzionamento è sufficiente una installazione base di una qualunque ditribuzione GNU/Linux (io ho utilizzato Debian).
Sono inoltre necessari i pacchetti wodim e dialog per la gestione della masterizzazione e per la reallizzazione dell'interfaccia grafica.
Lo script usa dei file di testo per la definizione degli elenchi di iso tra cui scegliere.

E' stato aggiunta la possibilità di eseguire la masterizzazione anche con il software di masterizzazione con interfaccia grafica xfburn. In questo caso deve essere attivo il server X e deve essere installato il software xfburn.

E' stata aggiunta la possibilità di masterizzare su device USB. In queto caso deve essere installato il software dd.

Per avere un feedback dell'esecuzione del comando dd, deve essere installato anche il software pv.
