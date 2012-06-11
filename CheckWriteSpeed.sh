#!/bin/bash
# A UNIX / Linux shell script to measure hard drive speed on linux
# This script write in the disk, and measure the disk speed.
# -------------------------------------------------------------------------
# Copyright (c) 2012 David Trigo <david.trigo@gmail.com>
# This script is licensed under GNU GPL version 3.0 or above
# -------------------------------------------------------------------------
# Last updated on : Feb-2012 - Script created.
# -------------------------------------------------------------------------

########################################################
########## INICIO VARIABLES DE CONFIGURACION ###########
########################################################

#El archivo temporal que se utilizara para hacer el test
#Debe ser un directorio del disco duro que queremos testear y el fichero temporal
test_file="/tmp/test"

#El tamano de los bloques con los que se haran el test
#deben ser consecutivos multiples de 2
bs="1024 2048 4096 8192 16384 32768 65536"

#El numero de veces que se hara el test con cada bloque, se hara la media
#Si es mayor que uno, se hara la desviacion estandar
n_times=3

#El tamano del archivo que se utilizara para el test (en BLOCKS) 1048576=1GB
count=1048576

#Se puede cambiar a 100MB
#count=102400

#La posicion del resultado que da 'dd'.
#Ejecutar: dd if=/dev/zero of=borrame bs=1024 count=10
#Mirar en que posicion esta el resultao en MB/s

#Ejemplo:
# >$ dd if=/dev/zero of=borrame bs=1024 count=10
# 10+0 records in
# 10+0 records out
# 10240 bytes (10 kB) copied, 9.7221e-05 s, 105 MB/s
#El 105 esta en la posicion 8 de la linea (separando por espacios)
pos=8

#Limpiar caches despues de cada test (recomendable). 1=si, 0=no
clearCaches=1

###############################################
############ INICIO DEL PROGRAMA ##############
###############################################

echo "Script para calcular el rendimiento del disco duro mediante dd"
echo "Recomendable abrirlo con un editor para configurar las opciones"
echo -ne "Se necesitan los programas: bc, cut, sed y bash\n"

n_count=0
total_results=0

for b in $bs; do
    actual=""
    time=0
    n_count=$[$n_count+1]
    echo -n "bs=$b count=$count "

    while [ $time -lt $n_times ]; do

        partial_result=$(dd if=/dev/zero of=$test_file bs=$b count=$count 2>&1 |grep "MB/s" | cut -d " " -f $pos | sed s/","/"."/)

        actual="$actual $partial_result"

        time=$[$time+1]

        rm -f $test_file

        #http://ubuntuforums.org/showthread.php?t=1196814
        if [ $clearCaches -eq 1 ]; then echo "3" > /proc/sys/vm/drop_caches; fi
    
        echo -n "."

    done

    #Hacemos la media de las medidas acumuladas para un mismo tamanyo de bloque

    media=0

    for a in $actual; do media=$(echo "$media + $a" | bc); done
    
    media=$(echo "$media / $n_times" | bc)

    total_results=$(echo "$total_results + $media" | bc)

    echo -n " $media MB/sec"

    #Hacemos la desviacion estandar para ver como se comporta y cuan fiable es la media

    if [ $n_times -gt 1 ]; then
        aux=0

        for a in $actual; do aux=$(echo "$aux+(($a - $media)*($a - $media))" | bc); done

        aux=$(echo "sqrt($aux/($n_times-1))"| bc)

        echo -n " Desviacion estandar $aux"

    fi

    #Disminuimos el numero de bloques para que el tamanyo del fichero sea el adecuado ya que se aumenta el tamanyo del bloque
    count=$[$count/2]

    echo ""

done

media=$(echo "$total_results / $n_count" | bc)

echo "Media: $media MB/sec"


