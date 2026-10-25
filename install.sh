#!/usr/bin/env bash
# Configura el miniteclado CH57x (USB 1189:8890) de 3 botones + 1 perilla.
#
# La configuración se graba en el firmware del propio teclado con
# ch57x-keyboard-tool, así que no hace falta dejar nada instalado ni
# ningún demonio corriendo: una vez programado funciona en cualquier equipo.
#
#   PC (por defecto): Ctrl+C | Ctrl+V | ImprPant
#   Mac (--mac):      Cmd+C  | Cmd+V  | Cmd+Shift+5
#   Perilla:          Vol- / Vol+, pulsar = silencio
#
# Para usar la distribución PC también en un Mac, ejecuta allí install-mac.sh.
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/jlcampana/mini-teclado/main/install.sh | bash
#   ... | bash -s -- --mac     # graba la distribución de Mac en el firmware
#   ... | bash -s -- --print   # solo muestra el YAML que se grabaría

set -euo pipefail

TOOL_VERSION="1.7.0"
TOOL_URL="https://github.com/kriomant/ch57x-keyboard-tool/releases/download/v${TOOL_VERSION}"
RAW_URL="https://raw.githubusercontent.com/jlcampana/mini-teclado/main"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m✔\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m✘\033[0m %s\n' "$*" >&2; exit 1; }

device_present() {
    case "$(uname -s)" in
        Linux) grep -qs '^1189$' /sys/bus/usb/devices/*/idVendor &&
               grep -qs '^8890$' /sys/bus/usb/devices/*/idProduct ;;
        Darwin) ioreg -p IOUSB -l 2>/dev/null | grep -q '"idProduct" = 34960' ;;
    esac
}

main() {
    local layout="pc" print_only=0
    for arg in "$@"; do
        case "$arg" in
            --mac) layout="mac" ;;
            --pc) layout="pc" ;;
            --print) print_only=1 ;;
            -h|--help) echo "Uso: install.sh [--pc | --mac] [--print]"; exit 0 ;;
            *) error "Opción desconocida: $arg" ;;
        esac
    done

    local os target
    os="$(uname -s)"
    case "$os-$(uname -m)" in
        Linux-x86_64) target="x86_64-unknown-linux-gnu" ;;
        Linux-aarch64|Linux-arm64) target="aarch64-unknown-linux-gnu" ;;
        Darwin-*) target="universal-apple-darwin" ;;
        *) error "Sistema no soportado: $os $(uname -m)" ;;
    esac

    local copy paste shot
    if [ "$layout" = "mac" ]; then
        copy="cmd-c"; paste="cmd-v"; shot="cmd-shift-5"
    else
        copy="ctrl-c"; paste="ctrl-v"; shot="printscreen"
    fi

    local mapping
    mapping="orientation: normal
rows: 1
columns: 3
knobs: 1
layers:
  - buttons:
      - [\"$copy\", \"$paste\", \"$shot\"]
    knobs:
      - ccw: volumedown
        press: mute
        cw: volumeup
"

    if [ "$print_only" = 1 ]; then
        printf '%s' "$mapping"
        exit 0
    fi

    device_present || error "No encuentro el miniteclado (USB 1189:8890). ¿Está enchufado?"
    command -v curl >/dev/null || error "Hace falta curl"
    command -v tar  >/dev/null || error "Hace falta tar"

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT

    info "Descargando ch57x-keyboard-tool v${TOOL_VERSION} ($target)"
    curl -fsSL "${TOOL_URL}/ch57x-keyboard-tool-${target}.tar.gz" | tar xz -C "$tmp"
    local tool="$tmp/ch57x-keyboard-tool"
    [ -x "$tool" ] || error "La descarga no contiene ch57x-keyboard-tool"

    printf '%s' "$mapping" > "$tmp/mapping.yaml"
    "$tool" validate < "$tmp/mapping.yaml" >/dev/null

    info "Grabando la distribución '$layout' en el teclado"
    if ! "$tool" upload < "$tmp/mapping.yaml" 2>/dev/null; then
        # Sin regla udev, en Linux el acceso USB directo requiere root.
        [ "$(id -u)" = 0 ] && error "No se pudo programar el teclado"
        info "Hace falta permiso de administrador para acceder al USB"
        sudo "$tool" upload < "$tmp/mapping.yaml" || error "No se pudo programar el teclado"
    fi
    ok "Teclado programado: [$copy] [$paste] [$shot] · perilla: volumen / silencio"

    # Lo que se graba se guarda para que remap.sh parta de ello.
    local conf="${XDG_CONFIG_HOME:-$HOME/.config}/mini-teclado/teclas.conf"
    mkdir -p "$(dirname "$conf")"
    printf 'b1=%s\nb2=%s\nb3=%s\nizq=volumedown\nder=volumeup\npulsar=mute\n' \
        "$copy" "$paste" "$shot" > "$conf"

    if [ "$os" = "Darwin" ] && [ "$layout" = "pc" ] &&
       ! grep -qs '"Mini teclado:' "$HOME/.config/karabiner/karabiner.json"; then
        echo
        info "Falta Karabiner: sin él, en este Mac los botones mandan Ctrl+C / Ctrl+V. Ejecuta:"
        echo "   curl -fsSL $RAW_URL/install-mac.sh | bash"
    elif [ "$os" = "Linux" ] && grep -qs '1189:8890' "$HOME/.config/input-remapper-2/config.json"; then
        echo
        info "input-remapper tiene un preset de autoload para este teclado."
        echo "   Ya no hace falta: desactívalo desde input-remapper-gtk para evitar remapeos dobles."
    fi
}

# Todo dentro de main para que, con curl | bash, nada lea del stdin del script.
main "$@"
