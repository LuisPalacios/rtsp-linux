# Full Cone NAT

Los streams de video IPTV que utiliza Movistar son de dos tipos: los canales normales (Multicast/UDP) y los videos bajo demanda (Unicast/UDP). Los últimos usan el protocolo `RTSP` que necesita que nuestro router soporte **Full Cone NAT**. Para implementarlo en linux necesitamos este repositorio, un [fork de **netfilter rtsp**](https://github.com/maru-sama/rtsp-linux). Se trata de un software libre llamado **rtsp-conntrack** que añade soporte para hacer lo necesario para que esto funcione. 

En el apunte [Videos bajo demanda para Movistar](https://www.luispa.com/linux/2014/10/18/movistar-bajo-demanda.html) tienes el detalle del caso de uso de este software, dejo aquí solo las notas sobre la instalación.


## Compilar módulos de kernel en Ubuntu

Para poder compilar módulos del kernel es necesario tener las cabeceras de Linux (linux-headers) instaladas. En ubuntu lo tenemos por defecto, pero lo compruebo, por si acaso :-)

```bash
sudo dpkg --list | grep linux-image
ii  linux-image-6.8.0-45-generic         6.8.0-45.45                                 amd64        Signed kernel image generic
ii  linux-image-generic                  6.8.0-45.45                                 amd64        Generic Linux kernel image

dpkg-query -s linux-headers-generic
Package: linux-headers-generic
Status: install ok installed
Priority: optional
Section: kernel
Installed-Size: 17
Maintainer: Ubuntu Kernel Team <kernel-team@lists.ubuntu.com>
Architecture: amd64
Source: linux-meta
Version: 6.8.0-45.45
Depends: linux-headers-6.8.0-45-generic
Description: Generic Linux kernel headers
 This package will always depend on the latest generic kernel headers
 available.
```

En ubuntu es necesario tener un clave para poder firmar los módulos que se van a cargar en el Kernel.

```bash
mkdir ~/keys-kernel-modules
cd keys-kernel-modules
```

Creo `x509.genkey`

```bash
[ req ]
default_bits = 4096
distinguished_name = req_distinguished_name
prompt = no
string_mask = utf8only
x509_extensions = myexts

[ req_distinguished_name ]
CN = Modules

[ myexts ]
basicConstraints=critical,CA:FALSE
keyUsage=digitalSignature
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid
```

Creo la clave

```bash
openssl req -new -nodes -utf8 -sha512 -days 36500 -batch -x509 -config x509.genkey -outform PEM -out signing_key.pem -keyout signing_key.priv
:

ls -al
total 20
drwxrwxr-x  2 luis luis 4096 oct 13 19:55 .
drwxr-x--- 12 luis luis 4096 oct 13 19:55 ..
-rw-rw-r--  1 luis luis 1773 oct 13 19:55 signing_key.pem
-rw-------  1 luis luis 3272 oct 13 19:55 signing_key.priv
-rw-rw-r--  1 luis luis  301 oct 13 19:55 x509.genkey
```

Copio las claves 

```bash
sudo cp ~/keys-kernel-modules/signing_key.*  /lib/modules/$(uname -r)/build/certs
```

## Compilar e instalar

- Instalación del módulo, fíjate que uso "debug" al hacer el make. Durante la fase de pruebas es importante para enterarte de lo que está pasando (log del kernel). Más adelante recompilo sin dicha opción.

```bash
___DESCARGA___

# cd ~/
wget https://github.com/LuisPalacios/rtsp-linux/archive/refs/heads/master.zip
unzip master.zip
rm master.zip
cd ~/rtsp-linux-master

___COMPILA___
make debug
:
```

## Firmar e instalar

Primero firmo los módulos

```bash
sudo /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 /lib/modules/$(uname -r)/build/certs/signing_key.priv /lib/modules/$(uname -r)/build/certs/signing_key.pem nf_conntrack_rtsp.ko
sudo /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 /lib/modules/$(uname -r)/build/certs/signing_key.priv /lib/modules/$(uname -r)/build/certs/signing_key.pem nf_nat_rtsp.ko
```

Los instalo

```bash
___INSTALA MODULOS KERNEL___
# sudo make modules_install
:
ls -al /lib/modules/6.8.0-45-generic/updates
total 1304
drwxr-xr-x 2 root root   4096 oct 13 19:48 .
drwxr-xr-x 6 root root   4096 oct 13 19:48 ..
-rw-r--r-- 1 root root 663386 oct 13 19:59 nf_conntrack_rtsp.ko
-rw-r--r-- 1 root root 662658 oct 13 19:59 nf_nat_rtsp.ko
```

Cargo los modulos, primero `depmod` para que relea todo lo que está disponible

```bash
sudo depmod -a
```

Cargo el módulo

```bash
sudo modprobe nf_nat_rtsp
:
lsmod | grep -i rtsp
nf_nat_rtsp            24576  0
nf_conntrack_rtsp      20480  1 nf_nat_rtsp
nf_nat                 61440  3 nf_nat_rtsp,nft_chain_nat,xt_MASQUERADE
nf_conntrack          196608  7 xt_conntrack,nf_nat,nf_conntrack_rtsp,nf_conntrack_netlink,nf_nat_rtsp,xt_CT,xt_MASQUERADE
```

## Configurar `conntrack`

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
:
etc... (el resto es igual que como describí arriba)
:
```

**Nota**: Recuerda que si compilas e instalas un nuevo Kernel, tendrás que recompilar e instalar de nuevo estos dos módulos.

Carga durante el boot, en gentoo hay que añadir lo siguiente al fichero `/etc/conf.d/modules` (en Gentoo)

```console
:
modules="nf_conntrack_rtsp"
modules="nf_nat_rtsp"
```

En Ubuntu, creo el fichero `/etc/modules-load.d/10-rtsp.conf`

```console
nf_nat_rtsp
```

No olvides configurar `conntrack` para que llame a los módulos del kernel, tienes dos formas distintas de hacerlo como veíamos arriba, acuérdate de ejecutarlo en algún momento durante el arranque de tu equipo:

- Kernel <= 5 : `sysctl -w net.netfilter.nf_conntrack_helper=1`
- Kernel >= 6 : `iptables -t raw -A PREROUTING -p tcp --dport 554 -j CT --helper rtsp`
