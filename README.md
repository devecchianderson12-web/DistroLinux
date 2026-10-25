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

## Instalar paquetes `.deb`

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
| Arranque de programas al iniciar sesión | `config/includes.chroot/etc/skel/.config/openbox/autostart` |
| Menú de clic derecho | `config/includes.chroot/etc/skel/.config/openbox/menu.xml` |
| Versión fija de RustDesk | variable `RUSTDESK_VERSION` (ej. `1.4.0`) al ejecutar `build.sh` |

Por defecto el idioma es español (Uruguay) con huso horario de Montevideo.

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
config/packages.chroot/        Aca se descarga el .deb de RustDesk
config/hooks/normal/           Habilita el servicio de RustDesk
config/includes.chroot/        Archivos que se copian dentro del sistema
.github/workflows/build-iso.yml  Construcción automática en GitHub
```
