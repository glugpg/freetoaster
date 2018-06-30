#!/bin/bash

for d in $(ls */ -d)
do
  cd $d 
  ../loadinfo.sh -t iso -f 45 -a -w
  for f in $(grep '| _'  --include=*.info --exclude=*.*~ -lR) 
  do 
    nano $f
  done
  cd ..
done
