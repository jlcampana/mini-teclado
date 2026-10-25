# mini-teclado

Configuración del miniteclado USB CH57x (`1189:8890`) de 3 botones y una perilla
para Fedora, Ubuntu (cualquier Linux) y macOS.

| Control       | PC (Linux/Windows) | Mac           |
|---------------|--------------------|---------------|
| Botón 1       | Ctrl+C             | Cmd+C         |
| Botón 2       | Ctrl+V             | Cmd+V         |
| Botón 3       | ImprPant           | Cmd+Shift+5   |
| Perilla ↺ / ↻ | Volumen − / +      | Volumen − / + |
| Pulsar perilla| Silencio           | Silencio      |

## Instalación

```bash
curl -fsSL https://raw.githubusercontent.com/jlcampana/mini-teclado/main/install.sh | bash
```

Detecta el sistema y graba la distribución correspondiente. Para forzar una:

```bash
curl -fsSL https://raw.githubusercontent.com/jlcampana/mini-teclado/main/install.sh | bash -s -- --mac
curl -fsSL https://raw.githubusercontent.com/jlcampana/mini-teclado/main/install.sh | bash -s -- --pc
```

`--print` muestra el YAML sin tocar el teclado.

## Cómo funciona

El script descarga [ch57x-keyboard-tool](https://github.com/kriomant/ch57x-keyboard-tool)
a un directorio temporal y graba las teclas **en el firmware del teclado**. No deja
nada instalado: ni input-remapper, ni reglas udev, ni demonios. El teclado manda
directamente las combinaciones, así que funciona igual en cualquier equipo.

Como lo que se graba es una sola distribución, si llevas el teclado de un PC a un
Mac hay que volver a ejecutar el script (o al revés).

En Linux, si no hay una regla udev que dé acceso al USB, pedirá `sudo` para grabar.

## Notas

- **macOS y HDMI:** macOS no deja cambiar el volumen de muchas salidas HDMI/DisplayPort
  con las teclas de volumen. Si pasa, [MonitorControl](https://github.com/MonitorControl/MonitorControl)
  lo soluciona y responde a esas mismas teclas.
- **input-remapper:** si antes usabas un preset para este teclado, desactívalo;
  ya no hace falta.
