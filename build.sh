#!/usr/bin/env bash
# =============================================================================
#  Construye la ISO de LiteDesk.
#  Ejecutar como root en Debian 13 (o en un contenedor debian:trixie --privileged).
#  Variables opcionales:
#    RUSTDESK_VERSION  version/tag de RustDesk a usar (por defecto, la ultima)
#    GITHUB_TOKEN      evita el limite de peticiones de la API de GitHub
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"

[ "$(id -u)" -eq 0 ] || { echo "Ejecutalo como root:  sudo bash build.sh"; exit 1; }
for c in lb curl jq sha256sum; do
	command -v "$c" >/dev/null || { echo "Falta '$c'. Instala:  apt-get install live-build curl jq"; exit 1; }
done

# Git/Windows pueden perder el bit de ejecucion o dejar saltos de linea CRLF: se arregla aca.
find auto config -type f ! -name '*.deb' -exec sed -i 's/\r$//' {} +
chmod +x auto/*
# Restos de versiones anteriores que rompen el build (el hook viejo corre antes que el nuevo)
rm -f config/hooks/normal/0100-rustdesk-servicio.hook.chroot
rm -rf config/packages.chroot

# ---------------------------------------------------------------- 1) RustDesk
# Se limpia antes de descargar (lb clean borra lo generado) y el .deb viaja dentro de la imagen
# en /opt/litedesk, donde lo recoge el hook config/hooks/normal/0100-rustdesk.hook.chroot.
lb clean --purge >/dev/null 2>&1 || true
PK=config/includes.chroot/opt/litedesk
rm -rf "$PK"
mkdir -p "$PK"

if [ -n "${RUSTDESK_VERSION:-}" ]; then
	api="https://api.github.com/repos/rustdesk/rustdesk/releases/tags/${RUSTDESK_VERSION}"
else
	api="https://api.github.com/repos/rustdesk/rustdesk/releases/latest"
fi
auth=()
[ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")

echo "==> Consultando RustDesk: $api"
json=$(curl -fsSL "${auth[@]}" -H "Accept: application/vnd.github+json" "$api")

# .deb de 64 bits (se descartan las variantes aarch64/armv7 y las "sciter")
read -r name url digest < <(printf '%s' "$json" | jq -r '
	[.assets[] | select(.name | test("x86_64\\.deb$")) | select(.name | test("sciter") | not)][0]
	| "\(.name) \(.browser_download_url) \(.digest // "-")"')

if [ -z "${name:-}" ] || [ "$name" = "null" ]; then
	echo "ERROR: no encontre el .deb x86_64 en esa version de RustDesk. Archivos disponibles:"
	printf '%s' "$json" | jq -r '.assets[].name'
	exit 1
fi

echo "==> Descargando $name"
curl -fL --retry 3 -o "$PK/$name" "$url"

if [[ "$digest" == sha256:* ]]; then
	esperado="${digest#sha256:}"
	real=$(sha256sum "$PK/$name" | cut -d' ' -f1)
	[ "$esperado" = "$real" ] || { echo "ERROR: el SHA-256 no coincide"; exit 1; }
	echo "==> SHA-256 verificado"
else
	echo "AVISO: GitHub no informo el SHA-256 de este archivo; no se pudo verificar."
fi
echo "$name" > RUSTDESK_VERSION_USADA.txt

# ---------------------------------------------------------------- 2) ISO
lb config
lb build 2>&1 | tee build.log

iso=$(ls -1 ./*.iso 2>/dev/null | head -n1 || true)
[ -n "$iso" ] || { echo "ERROR: no se genero ninguna ISO. Mira build.log"; exit 1; }

fecha=$(date +%Y%m%d)
destino="LiteDesk-${fecha}-amd64.iso"
mv "$iso" "$destino"
sha256sum "$destino" > "${destino}.sha256"
echo
echo "Listo: $destino ($(du -h "$destino" | cut -f1))"
