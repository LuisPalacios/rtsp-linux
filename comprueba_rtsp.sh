#!/bin/bash

# Comprobar si el módulo nf_nat_rtsp está cargado
if lsmod | grep -i rtsp > /dev/null; then
    echo "El módulo nf_nat_rtsp ya está cargado."
    exit 0
else
    echo "El módulo nf_nat_rtsp no está cargado. Procediendo a compilar e instalar."
    # Cambiar al directorio /root/rtsp-linux-master
    cd ~/rtsp-linux-master || { echo "No se pudo cambiar al directorio ~/rtsp-linux-master"; exit 1; }

    # Ejecutar el script compila_e_instala.sh
    if sudo ./compila_e_instala.sh; then
        echo "Compilación e instalación completada con éxito."
    else
        echo "Error al compilar e instalar."
        exit 1
    fi
fi

exit 0
