# LiteDesk

Distribución Linux de **bajo consumo** basada en **Debian 13 "trixie"**, pensada para equipos
modestos que se administran a distancia:

- Usa paquetes **`.deb`** y `apt` (es Debian de verdad, con todos sus repositorios).
- Trae **Firefox** (`firefox-esr`) ya instalado.
- Trae **RustDesk** preinstalado, con su **servicio habilitado desde el arranque**.
- Escritorio liviano: **Openbox + tint2 + LightDM** sobre **X11** (RustDesk funciona mejor sin
  atender sobre X11 que sobre Wayland) y memoria comprimida con **zram**.
- Es una ISO **live** (se prueba sin instalar) con **instalador** incluido.

> Esto es una *receta de construcción*: el repositorio no contiene la ISO, la genera
> GitHub Actions. Es un proyecto independiente, no afiliado a Debian, Mozilla ni RustDesk.

## Cómo obtener la ISO

1. Subí este contenido a un repositorio de GitHub.
2. Pestaña **Actions → "Construir ISO" → Run workflow**.
3. Esperá (30–60 min la primera vez). Al terminar, bajá la ISO desde **Artifacts**.

Para publicar un Release descargable: `git tag v1.0.0` y `git push origin v1.0.0`.

También se puede construir en tu PC con Debian 13 (o un contenedor):

```
sudo apt-get install live-build curl jq
sudo bash build.sh
```

o con Docker:

```
docker run --rm --privileged -v "$PWD":/w -w /w debian:trixie bash -c \
  "apt-get update && apt-get install -y live-build curl jq xorriso && bash build.sh"
```

## Cómo probarla

- **Primero en una máquina virtual** (VirtualBox, QEMU, VMware) con al menos 1 GB de RAM.
- Para un pendrive: Rufus (modo **DD**), balenaEtcher o Ventoy.
- En el menú de arranque hay **Live** (sin instalar) e **Install** (instalador de Debian).

## RustDesk: cómo dejarlo listo

El servicio arranca solo, pero un acceso sin atender necesita una clave fija:

```
sudo rustdesk --password TU_CLAVE_LARGA
sudo rustdesk --get-id
```

- **Modo live:** al apagar se pierde todo (incluido el ID y la clave de RustDesk). Sirve para
  probar o para asistencias puntuales. Para un equipo fijo, **instalala en el disco**.
- **Servidor propio:** configurá el servidor de ID/relay desde RustDesk (Ajustes → Red).
- **Seguridad:** RustDesk sin atender equivale a dejar abierta la puerta de la máquina. Usá
  una clave larga y única, y no reutilices la de otras cuentas.

## Qué trae el escritorio

Barra inferior con lanzadores: **Firefox**, **Archivos**, **Terminal**, **Instalar paquete .deb** y
**RustDesk**; al lado, las ventanas abiertas, la bandeja (icono de **wifi**) y el reloj.

| Quiero... | Cómo |
|---|---|
| Navegar carpetas | Lanzador *Archivos* (PCManFM, muy liviano) o `Super+E`. También lee pendrives. |
| Abrir una terminal | Lanzador *Terminal*, `Ctrl+Alt+T`, o clic derecho en el escritorio → Terminal |
| Instalar un `.deb` | Doble clic sobre el archivo, o lanzador *Instalar paquete .deb* (abre un selector de archivos). Se instala con `apt`, que resuelve las dependencias y pide confirmación. |
| Conectarme al wifi | Clic en el icono de red de la bandeja, elegir la red e ingresar la clave |
| Menú completo | Clic derecho sobre el escritorio |

**Wifi y drivers:** incluye NetworkManager y el firmware de las placas más comunes (Intel, Realtek,
Atheros, Broadcom, MediaTek, Ralink y otras). Si tu placa no aparece: en la terminal `rfkill list`
(para ver si está bloqueada) y `lspci -nn | grep -i net` o `lsusb` (para saber el modelo exacto), y
decime cuál es para agregar su driver. Probar el wifi **dentro de una máquina virtual no sirve**:
la VM solo tiene una placa de red virtual y no ve las redes inalámbricas; hay que probarlo en un
equipo real o pasarle un adaptador USB wifi a la VM.

**Instalado en el disco:** si en el instalador dejás vacía la contraseña de root, tu usuario queda con
`sudo` (lo necesita el instalador de `.deb`). Si definís una contraseña de root, tu usuario no podrá
usar `sudo`.

## Instalar paquetes `.deb` desde la terminal

```
sudo apt install ./programa.deb     # resuelve dependencias solo
sudo apt update && sudo apt install nombre-del-paquete
```

Usuario del modo live: `user` / contraseña `live`. En el sistema instalado se usa el usuario que
crees en el instalador.

## Personalizar

| Qué | Dónde |
|---|---|
| Idioma, teclado, zona horaria, nombre de la ISO | `auto/config` (línea `--bootappend-live`) |
| Programas incluidos | `config/package-lists/litedesk.list.chroot` |
| Barra inferior (lanzadores, reloj) | `config/includes.chroot/etc/xdg/tint2/tint2rc` |
| Instalador de .deb | `config/includes.chroot/usr/local/bin/litedesk-deb` |
| Atajos de teclado | `config/hooks/normal/0200-openbox-atajos.hook.chroot` |
| Arranque de programas al iniciar sesión | `config/includes.chroot/etc/xdg/openbox/autostart` |
| Menú de clic derecho | `config/includes.chroot/etc/xdg/openbox/menu.xml` |
| Versión fija de RustDesk | variable `RUSTDESK_VERSION` (ej. `1.4.0`) al ejecutar `build.sh` |

Por defecto el idioma es español (Uruguay) con huso horario de Montevideo.

## Si subís el proyecto desde la web de GitHub

La subida por arrastrar y soltar **puede omitir carpetas y archivos que empiezan con punto**
(`.github`, `.gitignore`...). Verificá que `.github/workflows/build-iso.yml` haya quedado en el
repositorio; si no, creálo desde *Add file → Create new file*. El resto del proyecto
evita carpetas ocultas a propósito.

## Limitaciones

- Solo **64 bits (amd64)**: Debian 13 ya no ofrece instalación en PCs de 32 bits.
- No medí el consumo real de memoria: probalo en tu equipo. Openbox + tint2 es de lo más liviano
  que hay, y Firefox será lo que más gaste.
- Si el build falla por el nombre de un paquete, el motivo queda en `build.log` (se sube como
  artefacto): corregí el nombre en la lista de paquetes y volvé a ejecutarlo.

## Estructura

```
build.sh                       Baja RustDesk y construye la ISO
auto/                          Configuración de live-build
config/package-lists/          Paquetes de Debian incluidos
config/hooks/normal/           Instala RustDesk y habilita su servicio
config/includes.chroot/opt/    Aca build.sh deja el .deb de RustDesk (temporal)
config/includes.chroot/        Archivos que se copian dentro del sistema
.github/workflows/build-iso.yml  Construcción automática en GitHub
```
