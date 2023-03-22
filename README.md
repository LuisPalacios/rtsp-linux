Los streams de video IPTV que utiliza Movistar son de dos tipos: los canales normales (Multicast/UDP) y los videos bajo demanda (Unicast/UDP). 

- Video bajo demanda para Movistar - (https://www.luispa.com/linux/2014/10/18/movistar-bajo-demanda.html) describo qué hay que hacer en un [router Linux para Movistar](https://www.luispa.com/linux/2014/10/05/router-linux.html) para que funcionen los "Videos bajo demanda". 

Utilizan el protocolo `RTSP` que necesita que nuestro router soporte **Full Cone NAT**. Para implementarlo en linux he hecho un [fork de **netfilter rtsp**](https://github.com/maru-sama/rtsp-linux), un software libre llamado **rtsp-conntrack** que añade soporte a nuestro linux para hacer lo necesario para que esto funcione. 

- Instalación del módulo, fíjate que uso "debug" al hacer el make. Durante la fase de pruebas es importante para enterarte de lo que está pasando (log del kernel). Más adelante recompilo sin dicha opción.

```console
 
___DESCARGA___
# cd ~/
# wget https://github.com/LuisPalacios/rtsp-linux/archive/refs/heads/master.zip
# unzip master.zip
# rm master.zip
# cd ~/rtsp-linux-master

___COMPILA___
# make debug
:

___INSTALA MODULOS KERNEL___
# make modules_install
:
# ls -al /lib/modules/3.17.0-gentoo/extra/
total 36
drwxr-xr-x 2 root root 4096 oct 18 16:37 .
drwxr-xr-x 5 root root 4096 oct 18 16:41 ..
-rw-r--r-- 1 root root 13305 oct 18 16:41 nf_conntrack_rtsp.ko
-rw-r--r-- 1 root root 11369 oct 18 16:41 nf_nat_rtsp.ko
```
