# mini-teclado

Configuración del miniteclado USB CH57x (`1189:8890`) de 3 botones y una perilla
para Fedora, Ubuntu (cualquier Linux) y macOS.

| Control        | Linux / Windows | Mac (con Karabiner) |
|----------------|-----------------|---------------------|
| Botón 1        | Ctrl+C          | Cmd+C               |
| Botón 2        | Ctrl+V          | Cmd+V               |
| Botón 3        | ImprPant        | Cmd+Shift+5         |
| Perilla ↺ / ↻  | Volumen − / +   | Volumen − / +       |
| Pulsar perilla | Silencio        | Silencio            |

## Linux (Fedora, Ubuntu…)

```bash
curl -fsSL https://raw.githubusercontent.com/jlcampana/mini-teclado/main/install.sh | bash
```

Graba las teclas **en el firmware del teclado** con
[ch57x-keyboard-tool](https://github.com/kriomant/ch57x-keyboard-tool), que se descarga
a un directorio temporal. No deja nada instalado: ni input-remapper, ni reglas udev,
ni demonios. Si no hay una regla udev que dé acceso al USB, pedirá `sudo`.

Una vez programado, el teclado funciona en cualquier Linux o Windows sin hacer nada más.

## macOS

En el Mac, primero se prepara el sistema y luego se programa el teclado:

```bash
curl -fsSL https://raw.githubusercontent.com/jlcampana/mini-teclado/main/install-mac.sh | bash
curl -fsSL https://raw.githubusercontent.com/jlcampana/mini-teclado/main/install.sh | bash
```

Si el teclado ya se programó en un Linux, el segundo paso no hace falta: el
firmware es el mismo para todos los sistemas.

### Qué hace `install-mac.sh`

El teclado manda Ctrl+C / Ctrl+V / ImprPant, que en macOS no copian, pegan ni hacen
capturas. En vez de reprogramarlo cada vez que cambias de equipo, el Mac traduce
las teclas solo para este teclado. Necesita [Homebrew](https://brew.sh) e instala:

- **[Karabiner-Elements](https://karabiner-elements.pqrs.org/)**: añade una regla
  limitada a este teclado (por vendor/product id), así que el teclado del Mac y los
  demás no cambian. Convierte la tecla Ctrl en Cmd (Ctrl+C → Cmd+C, Ctrl+V → Cmd+V…)
  e ImprPant en Cmd+Shift+5, así que cualquier combinación con Ctrl que grabes con
  `remap.sh` también funciona en el Mac.
  La regla se activa sola en el perfil activo de `~/.config/karabiner/karabiner.json`
  y se deja también como regla predefinida (`karabiner/mini-teclado.json`).
- **[MonitorControl](https://github.com/MonitorControl/MonitorControl)**: macOS no
  cambia el volumen de los monitores HDMI/DisplayPort. MonitorControl captura las
  teclas de volumen (las de la perilla) y lo cambia por DDC. Se añade a los ítems
  de inicio.

### Permisos de macOS (solo la primera vez)

macOS no deja concederlos desde un script; hay que activarlos a mano:

1. **Ajustes del Sistema → General → Ítems de inicio y extensiones → Extensiones de
   controladores**: activa *Karabiner-DriverKit-VirtualHIDDevice*.
2. **Privacidad y seguridad → Monitorización de entrada**: activa *karabiner_grabber*
   y *Karabiner-Core-Service*.
3. **Privacidad y seguridad → Accesibilidad**: activa *MonitorControl*.
4. Karabiner preguntará el tipo de teclado: elige el de tu Mac.

### Hacerlo a mano

Si prefieres no usar el script:

1. `brew install --cask karabiner-elements monitorcontrol`
2. Copia `karabiner/mini-teclado.json` a `~/.config/karabiner/assets/complex_modifications/`.
3. Karabiner-Elements → *Complex Modifications* → *Add predefined rule* → activa
   *Mini teclado CH57x*.
4. Abre MonitorControl y activa *Start at login* en sus ajustes.
5. Concede los permisos de arriba.

### Alternativa sin Karabiner

`install.sh --mac` graba Cmd+C / Cmd+V / Cmd+Shift+5 directamente en el firmware.
No hace falta Karabiner, pero entonces el teclado deja de copiar y pegar en Linux
hasta que vuelvas a ejecutar `install.sh` allí.

## Cambiar las acciones: `remap.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/jlcampana/mini-teclado/main/remap.sh | bash
```

Va preguntando control a control (botones 1–3, giro y pulsación de la perilla) con
un menú de acciones habituales y la opción de escribir una propia; Enter mantiene la
actual. Al final enseña el resultado y pide confirmación antes de grabarlo.

| Botones                                                   | Giro de la perilla            |
|-----------------------------------------------------------|-------------------------------|
| Copiar, pegar, cortar, deshacer, rehacer, guardar          | Volumen                       |
| Seleccionar todo, captura, play/pausa, pista sig./ant.     | Scroll                        |
| Silencio, bloquear pantalla, cambiar de ventana (Alt+Tab)  | Pistas, flechas, zoom, pestañas |

También funciona sin preguntas:

```bash
curl -fsSL …/remap.sh | bash -s -- --b1 ctrl-z --b2 ctrl-shift-z
curl -fsSL …/remap.sh | bash -s -- --izq wheelup --der wheeldown --pulsar play
curl -fsSL …/remap.sh | bash -s -- --mostrar   # configuración guardada
curl -fsSL …/remap.sh | bash -s -- --reset     # vuelve a copiar/pegar/captura/volumen
```

Acciones posibles: combinaciones (`ctrl-shift-t`, `alt-tab`), teclas (`f13`, `enter`),
multimedia (`play`, `next`, `mute`, `calculator`), ratón (`wheelup`, `click`) y
secuencias separadas por comas (`"ctrl-a,ctrl-c"`). La lista completa está en la
[documentación de ch57x-keyboard-tool](https://github.com/kriomant/ch57x-keyboard-tool/blob/master/doc/actions.md).
Las acciones no válidas se rechazan antes de grabar.

El teclado no permite leer lo que tiene grabado, así que la última configuración se
guarda en `~/.config/mini-teclado/teclas.conf` (también la de `install.sh`). En el Mac
usa Ctrl en las combinaciones: Karabiner las convierte en Cmd.

## Opciones de `install.sh`

| Opción    | Efecto                                            |
|-----------|---------------------------------------------------|
| (ninguna) | Graba la distribución PC (Ctrl)                   |
| `--mac`   | Graba la distribución Mac (Cmd) en el firmware    |
| `--print` | Muestra el YAML sin tocar el teclado              |

Con `curl … | bash -s -- --mac`.

## input-remapper

Si antes usabas un preset de input-remapper para este teclado, desactívalo; ya no hace falta.
