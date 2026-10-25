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
  demás no cambian. Ctrl+C → Cmd+C, Ctrl+V → Cmd+V, ImprPant → Cmd+Shift+5.
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

## Opciones de `install.sh`

| Opción    | Efecto                                            |
|-----------|---------------------------------------------------|
| (ninguna) | Graba la distribución PC (Ctrl)                   |
| `--mac`   | Graba la distribución Mac (Cmd) en el firmware    |
| `--print` | Muestra el YAML sin tocar el teclado              |

Con `curl … | bash -s -- --mac`.

## input-remapper

Si antes usabas un preset de input-remapper para este teclado, desactívalo; ya no hace falta.
