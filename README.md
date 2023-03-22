Los streams de video IPTV que utiliza Movistar son de dos tipos: los canales normales (Multicast/UDP) y los videos bajo demanda (Unicast/UDP). Los últimos usan el protocolo `RTSP` que necesita que nuestro router soporte **Full Cone NAT**. Para implementarlo en linux necesitamos este repositorio, un [fork de **netfilter rtsp**](https://github.com/maru-sama/rtsp-linux). Se trata de un software libre llamado **rtsp-conntrack** que añade soporte para hacer lo necesario para que esto funcione. 

En el apunte [Videos bajo demanda para Movistar](https://www.luispa.com/linux/2014/10/18/movistar-bajo-demanda.html) tienes el detalle del caso de uso de este software, dejo aquí solo las notas sobre la instalación.

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

- Cargo el nuevo módulo en el Kernel

Una vez terminada la compilación e instalación anterior ya puedes cargar los módulos en el Kernel:

```console 
# modprobe nf_conntrack_rtsp  (Este módulo se ejecuta al "detectar" el SETUP RTSP)
# modprobe nf_nat_rtsp        (Este módulo se encarga de establecer la asociación (dnat))
 
````


- A continuación tenemos que configurar `conntrack` para que llame a los módulos del kernel. Hay dos formas de hacerlo, dependiendo de qué versíon del kernel tengas: 

- Kernel <= 5 : `sysctl -w net.netfilter.nf_conntrack_helper=1`
- Kernel >= 6 : `iptables -t raw -A PREROUTING -p tcp --dport 554 -j CT --helper rtsp`

- Te vuelves a tu Deco, entras en el menú Movistar TV, busca una grabación y pula en "ver", debería funcionar. Puedes comprobar con el comando dmesg que la asociación es correcta, algo parecido a lo siguiente:

```console
# dmesg
[358463.389458] nf_conntrack_rtsp v0.7.2 loading
[358463.389462] port #0: 554
[359189.716507] nf_nat_rtsp v0.7.2 loading
:
[359263.569596] conntrackinfo = 2
[359263.576080] IP_CT_DIR_REPLY
[359263.583559] IP_CT_DIR_REPLY
[359263.585568] found a setup message
[359263.585577] tran='Transport: MP2T/H2221/UDP;unicast;client_port=27336'
[359263.585596] lo port found : 27336
[359263.585597] udp transport found, ports=(0,27336,27336)
[359263.585600] expect_related 0.0.0.0:0-10.214.XX.YY:27336
[359263.585601] NAT rtsp help_out
[359263.585603] hdr: len=9, CSeq: 3
[359263.585604] hdr: len=25, User-Agent: MICA-IP-STB
[359263.585605] hdr: len=53, Transport: MP2T/H2221/UDP;unicast;client_port=27336
[359263.585606] hdr: Transport
[359263.585608] stunaddr=10.214.XX.YY (auto)
[359263.585610] using port 27336
[359263.585613] rep: len=53, Transport: MP2T/H2221/UDP;unicast;client_port=27336
[359263.585614] hdr: len=14, x-mayNotify:
[359263.624565] IP_CT_DIR_REPLY
[359263.718991] IP_CT_DIR_REPLY
[359263.992779] IP_CT_DIR_REPLY
[359264.285029] IP_CT_DIR_REPLY
```
Una vez lo tengas todo funcionando te recomiendo que recompiles sin "debug", vuelvas a instalar los módulos y programes su carga durante el arranque del equipo. 

Recompila e instala

```console
# cd /tmp/rtsp
# make clean
# make
# make modules_install   (quedan copiados en /lib/modules/3.17.0-gentoo/extra/)
:
```

**Nota**: Recuerda que si compilas e instalas un nuevo Kernel, tendrás que recompilar e instalar de nuevo estos dos módulos.

Carga durante el boot, en gentoo hay que añadir lo siguiente al fichero `/etc/conf.d/modules` (en Gentoo)

```console
:
modules="nf_conntrack_rtsp"
modules="nf_nat_rtsp"
```

En Ubuntu, añade al fichero `/etc/modules`

```console
nf_nat_rtsp
```

No olvides configurar `conntrack` para que llame a los módulos del kernel, tienes dos formas distintas de hacerlo como veíamos arriba, acuérdate de ejecutarlo en algún momento durante el arranque de tu equipo:

- Kernel <= 5 : `sysctl -w net.netfilter.nf_conntrack_helper=1`
- Kernel >= 6 : `iptables -t raw -A PREROUTING -p tcp --dport 554 -j CT --helper rtsp`
