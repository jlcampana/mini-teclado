#!/usr/bin/env bash
# macOS: hace que el miniteclado CH57x (USB 1189:8890), programado con la
# distribución PC (Ctrl+C | Ctrl+V | ImprPant), funcione como en un Mac:
#
#   Ctrl+C → Cmd+C   Ctrl+V → Cmd+V   ImprPant → Cmd+Shift+5
#
# Instala con Homebrew:
#   - Karabiner-Elements, con una regla que solo afecta a este teclado; el
#     teclado del Mac y los demás siguen igual.
#   - MonitorControl, para que la perilla cambie el volumen también en
#     monitores HDMI/DisplayPort, que macOS no controla por sí mismo.
#
# Uso (en el Mac, primero este y luego install.sh para programar el teclado):
#   curl -fsSL https://raw.githubusercontent.com/jlcampana/mini-teclado/main/install-mac.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/jlcampana/mini-teclado/main/install.sh | bash

set -euo pipefail

RAW_URL="https://raw.githubusercontent.com/jlcampana/mini-teclado/main"
RULE_DESCRIPTION_PREFIX="Mini teclado:"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m✔\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m!\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m✘\033[0m %s\n' "$*" >&2; exit 1; }

install_cask() {
    local cask=$1 app=$2 brew
    if [ -d "/Applications/$app.app" ]; then
        ok "$app ya está instalado"
        return
    fi
    brew="$(find_brew)" || error "Hace falta Homebrew (https://brew.sh) para instalar $app"
    info "Instalando $app con Homebrew"
    "$brew" install --cask "$cask" < /dev/null
}

find_brew() {
    command -v brew 2>/dev/null && return
    local b
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [ -x "$b" ] && { echo "$b"; return; }
    done
    return 1
}

main() {
    [ "$(uname -s)" = "Darwin" ] || error "Este script es solo para macOS"

    local config_dir="$HOME/.config/karabiner"
    local assets="$config_dir/assets/complex_modifications"

    install_cask karabiner-elements Karabiner-Elements
    install_cask monitorcontrol MonitorControl

    # La regla queda también como "predefined rule" por si hay que reactivarla a mano.
    mkdir -p "$assets"
    curl -fsSL "$RAW_URL/karabiner/mini-teclado.json" -o "$assets/mini-teclado.json"

    # Activa la regla en el perfil seleccionado de karabiner.json; Karabiner
    # recarga el fichero solo al detectar el cambio. Python viene con las
    # Command Line Tools, que Homebrew ya exige.
    if python3 -c '' 2>/dev/null; then
        python3 -I - "$config_dir/karabiner.json" "$assets/mini-teclado.json" "$RULE_DESCRIPTION_PREFIX" <<'EOF'
import json, os, sys
config_path, rule_path, prefix = sys.argv[1:]
if os.path.exists(config_path):
    with open(config_path) as f:
        config = json.load(f)
else:
    config = {}
profiles = config.setdefault("profiles", [])
if not profiles:
    profiles.append({"name": "Default profile", "selected": True})
profile = next((p for p in profiles if p.get("selected")), profiles[0])
rules = profile.setdefault("complex_modifications", {}).setdefault("rules", [])
rules[:] = [r for r in rules if not r.get("description", "").startswith(prefix)]
with open(rule_path) as f:
    rules.extend(json.load(f)["rules"])
tmp = config_path + ".tmp"
with open(tmp, "w") as f:
    json.dump(config, f, indent=4)
os.replace(tmp, config_path)
EOF
        ok "Regla del miniteclado activada en Karabiner"
    else
        warn "No hay python3: actívala a mano en Karabiner-Elements →"
        warn "Complex Modifications → Add predefined rule → 'Mini teclado CH57x'"
    fi

    open -a "Karabiner-Elements" || true

    # MonitorControl no se arranca solo al iniciar sesión si no se le añade.
    if ! osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | grep -q MonitorControl; then
        osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/MonitorControl.app", hidden:true}' >/dev/null 2>&1 &&
            ok "MonitorControl se abrirá al iniciar sesión" ||
            warn "No pude añadir MonitorControl a los ítems de inicio; actívalo en sus ajustes"
    fi
    open -a "MonitorControl" || true

    echo
    info "Si es la primera vez que usas Karabiner, macOS pedirá permisos:"
    echo "   - Ajustes del Sistema → General → Ítems de inicio y extensiones →"
    echo "     Extensiones de controladores: activa Karabiner-DriverKit-VirtualHIDDevice"
    echo "   - Ajustes del Sistema → Privacidad y seguridad → Monitorización de entrada:"
    echo "     activa karabiner_grabber y Karabiner-Core-Service"
    echo "   - Karabiner preguntará el tipo de teclado: elige el de tu Mac."
    echo "   - Ajustes del Sistema → Privacidad y seguridad → Accesibilidad:"
    echo "     activa MonitorControl (para que capture las teclas de volumen)"
    echo
    info "Con un monitor externo, MonitorControl cambia su volumen por DDC; si el"
    echo "   monitor no admite DDC, usa volumen por software (ajustes de MonitorControl)."

    echo
    info "Último paso: programa el teclado (si ya lo programaste en Linux, no hace falta):"
    echo "   curl -fsSL $RAW_URL/install.sh | bash"
}

# Todo dentro de main para que, con curl | bash, nada lea del stdin del script.
main "$@"
