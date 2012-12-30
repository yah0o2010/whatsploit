#!/bin/bash

## whatsappquery by alister
## script que nos informa de si un numero o lista de numeros de telefono tiene whatsapp
## el script añade los resultados automaticamente al fichero whatsappusers.list
## e informa en pantalla con un YES/NO

## uso:
## ./whatsappquery lista_numeros.list
## donde lista_numeros es un archivo de texto con un numero de telf por linea

## uso 2:
## ./whatsappquery
## en modo interactivo, whatsappquery esperará que introduzcamos numeros y pulsemos enter
## para mostarnos los resultados en pantalla
## control+c cerrara la aplicacion

## countryprefix: prefijo del pais de los numeros de telefono que vamos a sondear
## si la lista de numeros ya contiene el prefijo, se puede dejar esta variable en blanco
#countryprefix=34
countryprefix=

## max_parallel: cantidad maxima de ataques simultaneos (procesos hijos)
export max_parallel=20

## === FUNCTIONS ===
children_throttle() {
# gestionamos los procesos hijos en rafagas
# primero entramos en un bucle de espera infinita
# luego contamos los procesos, descontando uno a la cantidad, ya que ps tambien es un proceso
# pero no cuenta como numero de telefono al que estamos atacando simultaneamente
# salimos del bucle cuando el numero de procesos paralelos hijos (num_parallel) es menor que max_parallel
# de modo que queda espacio para crear otro proceso hijo
let num_parallel=`ps --no-headers -o pid --ppid=$$ | wc -w`-1
until [ $num_parallel -lt $max_parallel ]; do
  let num_parallel=`ps --no-headers -o pid --ppid=$$ | wc -w`-1
done
## DEBUG: controlando el numero de procesos hijos. debe ser siempre menos de max_parallel
# echo DEBUG: num_parallel=${num_parallel} - max_parallel=${max_parallel}
}

## === START ===
mkdir -p tmpfiles

num_parallel=0
set -bm
# entramos en el main loop
while read number; do 

# ver la funcion children_throttle arriba para mas info
children_throttle

# tomamos el countryprefix, que es una constante configurable del script,
# la sumamos a la linea que estamos leyendo de la lista de numeros a atacar,
# y con eso obtenemos un target valido, con el formato de usuario de whatsapp.
# si el target es 600123456 y el countryprefix es el de españa (34), entonces
# el usuario de whatsapp sera 34600123456
let i=$i+1
numberwithprefix=${countryprefix}${number}
if [ "$1" != "" ]; then
  # si hemos recibido como parametro una lista
  # añadimos un pequeño contador "i" para saber por que linea del archivo vamos
  echo [Query ][${i}] ${numberwithprefix}
else
  # en modo interactivo el contador deja de tener sentido
  echo [Query ] ${numberwithprefix}
fi


( wget "https://sro.whatsapp.net/client/iphone/iq.php?cd=1&cc=${countryprefix}&me=${number}&u[]=%2B${numberwithprefix}" -q -O tmpfiles/${numberwithprefix}

# a continuacion un pequeño hack para saber si el usuario esta registrado en whatsapp
# si la respuesta del servidor contiene este patron de dos lineas contiguas:
# <array> 
# </array>
# podemos asegurar que el array de la respuesta está vacio ergo no hay datos para ese usuario
# el siguiente fragmento de codigo simplemente trata de evaluar esa condicion y actua en consecuencia
# el uso del control de contexto -A de grep y una tuberia nos resuelven este problema

grep -A 1 "<array>" tmpfiles/${numberwithprefix} | grep -q "</array>"
exitcode=$?
case $exitcode in
0 ) 
## echo ESTE MENSAJE SALE CUANDO EL NUMERO NO TIENE WHATSAPP
echo [Answer][${numberwithprefix}] NO
;;
* )
## echo ESTE MENSAJE SALE CUANDO EL NUMERO SI TIENE WHATSAPP
echo [Answer][${numberwithprefix}] YES
echo ${numberwithprefix} >> whatsappusers.list
;;
esac) & 
done  < "${1:-/proc/${$}/fd/0}"
# esperamos a que finalicen todos los procesos hijos
echo [Control] Lista procesada. Esperando procesos hijos...
wait 
echo [Control] Todos los procesos hijos finalizados. Limpiando...
# limpiamos todos los tmps
rm -rf tmpfiles
