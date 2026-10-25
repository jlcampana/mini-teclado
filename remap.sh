#!/usr/bin/env bash
# Cambia las acciones del miniteclado CH57x (USB 1189:8890) y las graba en su
# firmware con ch57x-keyboard-tool. Funciona en Linux y macOS.
#
# Sin opciones pregunta control a control (Enter mantiene el valor actual).
# El teclado no permite leer lo que tiene grabado, así que la última
# configuración se guarda en ~/.config/mini-teclado/teclas.conf.
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/jlcampana/mini-teclado/main/remap.sh | bash
#   ... | bash -s -- --b1 ctrl-z --b2 ctrl-shift-z     # sin preguntas
#   ... | bash -s -- --izq wheelup --der wheeldown --pulsar play
#   ... | bash -s -- --mostrar                         # muestra la configuración guardada
#   ... | bash -s -- --reset                           # vuelve a la de fábrica del repo
#
# Acciones: ctrl-c, alt-tab, ctrl-shift-z, f13, printscreen, play, next, prev,
# mute, volumeup, volumedown, screenlock, calculator, wheelup, wheeldown,
# click, "ctrl-a,ctrl-c" (secuencia)... Lista completa en
# https://github.com/kriomant/ch57x-keyboard-tool/blob/master/doc/actions.md
#
# En macOS usa Ctrl: si está instalado install-mac.sh, Karabiner lo convierte en Cmd.

set -euo pipefail

TOOL_VERSION="1.7.0"
TOOL_URL="https://github.com/kriomant/ch57x-keyboard-tool/releases/download/v${TOOL_VERSION}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/mini-teclado/teclas.conf"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m✔\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m!\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m✘\033[0m %s\n' "$*" >&2; exit 1; }

# Valores por defecto (los mismos que install.sh).
set_defaults() {
    b1="ctrl-c"; b2="ctrl-v"; b3="printscreen"
    izq="volumedown"; der="volumeup"; pulsar="mute"
}

load_conf() {
    set_defaults
    [ -f "$CONF" ] || return 0
    local key value
    while IFS='=' read -r key value; do
        case "$key" in
            b1|b2|b3|izq|der|pulsar) [ -n "$value" ] && printf -v "$key" '%s' "$value" ;;
        esac
    done < "$CONF"
}

save_conf() {
    mkdir -p "$(dirname "$CONF")"
    printf 'b1=%s\nb2=%s\nb3=%s\nizq=%s\nder=%s\npulsar=%s\n' \
        "$b1" "$b2" "$b3" "$izq" "$der" "$pulsar" > "$CONF"
}

mapping_yaml() {
    cat <<EOF
orientation: normal
rows: 1
columns: 3
knobs: 1
layers:
  - buttons:
      - ["$1", "$2", "$3"]
    knobs:
      - ccw: "$4"
        press: "$6"
        cw: "$5"
EOF
}

show() {
    printf '  Botón 1: %s\n  Botón 2: %s\n  Botón 3: %s\n' "$b1" "$b2" "$b3"
    printf '  Perilla ↺: %s   ↻: %s   pulsar: %s\n' "$izq" "$der" "$pulsar"
}

device_present() {
    case "$(uname -s)" in
        Linux) grep -qs '^1189$' /sys/bus/usb/devices/*/idVendor &&
               grep -qs '^8890$' /sys/bus/usb/devices/*/idProduct ;;
        Darwin) ioreg -p IOUSB -l 2>/dev/null | grep -q '"idProduct" = 34960' ;;
    esac
}

download_tool() {
    local target
    case "$(uname -s)-$(uname -m)" in
        Linux-x86_64) target="x86_64-unknown-linux-gnu" ;;
        Linux-aarch64|Linux-arm64) target="aarch64-unknown-linux-gnu" ;;
        Darwin-*) target="universal-apple-darwin" ;;
        *) error "Sistema no soportado: $(uname -s) $(uname -m)" ;;
    esac
    info "Descargando ch57x-keyboard-tool v${TOOL_VERSION}"
    curl -fsSL "${TOOL_URL}/ch57x-keyboard-tool-${target}.tar.gz" | tar xz -C "$tmp"
    tool="$tmp/ch57x-keyboard-tool"
    [ -x "$tool" ] || error "La descarga no contiene ch57x-keyboard-tool"
}

# Comprueba una acción suelta con el validador de la herramienta.
valid_action() {
    mapping_yaml "$1" "$1" "$1" "$1" "$1" "$1" | "$tool" validate >/dev/null 2>&1
}

BUTTON_MENU=(
    "ctrl-c|Copiar"
    "ctrl-v|Pegar"
    "ctrl-x|Cortar"
    "ctrl-z|Deshacer"
    "ctrl-shift-z|Rehacer"
    "ctrl-s|Guardar"
    "ctrl-a|Seleccionar todo"
    "printscreen|Captura de pantalla"
    "play|Play / pausa"
    "next|Pista siguiente"
    "prev|Pista anterior"
    "mute|Silencio"
    "screenlock|Bloquear pantalla"
    "alt-tab|Cambiar de ventana"
)

KNOB_MENU=(
    "volumedown volumeup|Volumen"
    "wheelup wheeldown|Scroll"
    "prev next|Pista anterior / siguiente"
    "left right|Flecha izquierda / derecha"
    "up down|Flecha arriba / abajo"
    "ctrl-minus ctrl-equal|Zoom − / +"
    "ctrl-shift-tab ctrl-tab|Pestaña anterior / siguiente"
)

prompt() { printf '%s' "$1" > /dev/tty; read -r REPLY < /dev/tty; }

# ask_action VAR "Título": elige una acción del menú de botones o una propia.
ask_action() {
    local var=$1 title=$2 current=${!1} i entry
    while true; do
        printf '\n\033[1m%s\033[0m (actual: %s)\n' "$title" "$current" > /dev/tty
        for i in "${!BUTTON_MENU[@]}"; do
            entry=${BUTTON_MENU[$i]}
            printf '  %2d) %-20s %s\n' $((i + 1)) "${entry#*|}" "${entry%%|*}" > /dev/tty
        done
        printf '   o) Otra (escribirla)\n' > /dev/tty
        prompt "Opción [Enter = mantener]: "
        case "$REPLY" in
            "") return ;;
            o|O)
                prompt "Acción (p. ej. ctrl-shift-t, f13, \"ctrl-a,ctrl-c\"): "
                if [ -n "$REPLY" ] && valid_action "$REPLY"; then
                    printf -v "$var" '%s' "$REPLY"; return
                fi
                warn "Acción no válida: '$REPLY'" ;;
            *)
                if [[ "$REPLY" =~ ^[0-9]+$ ]] && [ "$REPLY" -ge 1 ] && [ "$REPLY" -le ${#BUTTON_MENU[@]} ]; then
                    entry=${BUTTON_MENU[$((REPLY - 1))]}
                    printf -v "$var" '%s' "${entry%%|*}"; return
                fi
                warn "Opción no válida" ;;
        esac
    done
}

ask_knob() {
    local i entry pair
    while true; do
        printf '\n\033[1mGiro de la perilla\033[0m (actual: ↺ %s / ↻ %s)\n' "$izq" "$der" > /dev/tty
        for i in "${!KNOB_MENU[@]}"; do
            entry=${KNOB_MENU[$i]}
            printf '  %2d) %s\n' $((i + 1)) "${entry#*|}" > /dev/tty
        done
        printf '   o) Otra (escribir cada sentido)\n' > /dev/tty
        prompt "Opción [Enter = mantener]: "
        case "$REPLY" in
            "") return ;;
            o|O)
                local a b
                prompt "Girar a la izquierda ↺: "; a=$REPLY
                prompt "Girar a la derecha ↻: "; b=$REPLY
                if [ -n "$a" ] && [ -n "$b" ] && valid_action "$a" && valid_action "$b"; then
                    izq=$a; der=$b; return
                fi
                warn "Acción no válida" ;;
            *)
                if [[ "$REPLY" =~ ^[0-9]+$ ]] && [ "$REPLY" -ge 1 ] && [ "$REPLY" -le ${#KNOB_MENU[@]} ]; then
                    pair=${KNOB_MENU[$((REPLY - 1))]%%|*}
                    izq=${pair% *}; der=${pair#* }; return
                fi
                warn "Opción no válida" ;;
        esac
    done
}

main() {
    load_conf

    local interactive=1 show_only=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --b1|--b2|--b3|--izq|--der|--pulsar)
                [ $# -ge 2 ] || error "Falta el valor de $1"
                printf -v "${1#--}" '%s' "$2"; interactive=0; shift ;;
            --reset) set_defaults; interactive=0 ;;
            --mostrar) show_only=1 ;;
            -h|--help)
                echo "Uso: remap.sh [--b1 X] [--b2 X] [--b3 X] [--izq X] [--der X] [--pulsar X] [--reset] [--mostrar]"
                exit 0 ;;
            *) error "Opción desconocida: $1" ;;
        esac
        shift
    done

    if [ "$show_only" = 1 ]; then
        [ -f "$CONF" ] || warn "No hay configuración guardada; estos son los valores por defecto"
        show
        exit 0
    fi

    command -v curl >/dev/null || error "Hace falta curl"
    command -v tar  >/dev/null || error "Hace falta tar"
    device_present || error "No encuentro el miniteclado (USB 1189:8890). ¿Está enchufado?"

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    download_tool

    if [ "$interactive" = 1 ]; then
        { : < /dev/tty; } 2>/dev/null || error "Sin terminal: usa las opciones --b1, --b2…"
        echo
        info "Configuración actual:"
        show
        ask_action b1 "Botón 1"
        ask_action b2 "Botón 2"
        ask_action b3 "Botón 3"
        ask_knob
        ask_action pulsar "Pulsar la perilla"
        echo
        info "Nueva configuración:"
        show
        prompt "¿Grabar en el teclado? [S/n] "
        case "$REPLY" in n|N) echo "Cancelado."; exit 0 ;; esac
    fi

    mapping_yaml "$b1" "$b2" "$b3" "$izq" "$der" "$pulsar" > "$tmp/mapping.yaml"
    "$tool" validate < "$tmp/mapping.yaml" >/dev/null || error "La configuración no es válida"

    info "Grabando en el teclado"
    if ! "$tool" upload < "$tmp/mapping.yaml" 2>/dev/null; then
        # Sin regla udev, en Linux el acceso USB directo requiere root.
        [ "$(id -u)" = 0 ] && error "No se pudo programar el teclado"
        info "Hace falta permiso de administrador para acceder al USB"
        sudo "$tool" upload < "$tmp/mapping.yaml" || error "No se pudo programar el teclado"
    fi
    save_conf
    ok "Teclado programado:"
    show
}

# Todo dentro de main para que, con curl | bash, nada lea del stdin del script.
main "$@"
