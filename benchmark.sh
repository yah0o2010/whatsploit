#!/bin/bash
inicio=`date +%s`
./whatsploit.sh benchmark.list
wait
fin=`date +%s`
let total=$fin-$inicio
echo "ha tardado ${total} segundos"
