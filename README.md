# glue

> Un único lenguaje de comandos para gestionar paquetes, sin importar en qué distribución de Linux estés.

![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-GNU_GPL_v3-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

**Estado:** 🚧 en fase de diseño — este README define la arquitectura y el alcance de la v1. La implementación en `bash` está en marcha.

---

## 🧩 ¿Qué es `glue`?

`glue` es una capa de abstracción, escrita en bash puro, que se sitúa entre tú y el gestor de paquetes nativo de cada distribución Linux. Su objetivo es simple: que nunca más tengas que recordar qué comando usa cada sistema.

El nombre no es casual: `glue` (pegamento) es literalmente lo que hace — pega tu forma de trabajar habitual sobre cualquier sistema, en lugar de obligarte a adaptarte tú a cada uno.

## 🚧 El problema

Cada familia de distribuciones trae su propio gestor de paquetes, con su propia sintaxis:

- **Debian, Ubuntu, Mint, Pop!_OS** → `apt`, `apt-get`, `dpkg`
- **Arch, Manjaro, EndeavourOS, CachyOS** → `pacman` (y helpers de AUR como `yay` o `paru`)
- **Fedora, RHEL, Rocky, AlmaLinux** → `dnf` (`yum` en versiones antiguas)
- **openSUSE, SLES** → `zypper`
- **Alpine** → `apk`
- **Void** → `xbps`
- **Gentoo** → `emerge`

El resultado es memoria muscular rota constantemente: `apt install` no existe en Arch, `pacman -S` no existe en Debian, y cada vez que saltas entre tu portátil, un servidor, un contenedor o una VPS, pierdes segundos (y paciencia) recordando la sintaxis correcta. Las soluciones habituales — chuletas mentales, dotfiles con alias mantenidos a mano y sincronizados entre máquinas — son parches, no soluciones.

## ⚙️ Cómo funciona

1. **Detección del sistema.** Al cargar `glue`, se parsean los campos `ID` e `ID_LIKE` de `/etc/os-release` para identificar tanto la distribución exacta como su familia.
2. **Resolución del backend.** Con la distro identificada, `glue` comprueba qué gestor de paquetes nativo está realmente disponible en el `$PATH` — no basta con saber la distro en teoría, se verifica el binario en la práctica.
3. **Elección de dialecto.** Configuras una vez qué sintaxis quieres usar (tu "dialecto": `apt`, `pacman`, `dnf`...). No tiene por qué coincidir con el backend real de la máquina en la que estás — de hecho, ese es precisamente el punto.
4. **Traducción y ejecución.** `glue` define funciones de shell que interceptan los verbos de tu dialecto (`install`, `remove`, `update`, `search`...) y los traducen a la invocación real del backend nativo, incluyendo matices como la distinción entre refrescar metadatos y actualizar paquetes.

```
┌──────────────┐     ┌──────────────────┐     ┌───────────────────┐     ┌──────────────────┐
│   Tú          │ --> │  Tu dialecto      │ --> │   Motor de glue    │ --> │  Backend nativo   │
│ "apt install" │     │  (sintaxis apt)   │     │ (traducción según  │     │ (pacman, dnf,     │
│               │     │                   │     │  el sistema real)  │     │  zypper, apk...)  │
└──────────────┘     └──────────────────┘     └───────────────────┘     └──────────────────┘
                                                          ▲
                                                          │
                                                 /etc/os-release
                                                  (ID, ID_LIKE)
```

Extracto ilustrativo de la lógica de detección (`lib/detect.sh`):

```bash
source /etc/os-release

case "$ID" in
  arch|manjaro|endeavouros|cachyos)  GLUE_BACKEND="pacman" ;;
  debian|ubuntu|linuxmint|pop)       GLUE_BACKEND="apt"    ;;
  fedora|rhel|rocky|almalinux)       GLUE_BACKEND="dnf"    ;;
  opensuse*|sles)                    GLUE_BACKEND="zypper" ;;
  alpine)                            GLUE_BACKEND="apk"    ;;
  *)
    # Fallback para derivadas no listadas explícitamente
    case "$ID_LIKE" in
      *arch*)           GLUE_BACKEND="pacman" ;;
      *debian*)         GLUE_BACKEND="apt"    ;;
      *fedora*|*rhel*)  GLUE_BACKEND="dnf"    ;;
      *suse*)           GLUE_BACKEND="zypper" ;;
      *)                GLUE_BACKEND=""       ;; # no detectado
    esac
    ;;
esac
```

> **Nota real, no hipotética:** confiar solo en `ID_LIKE` no es tan bulletproof como parece. Durante 2025 y todavía a principios de 2026 se reportó en varios proyectos (`topgrade`, `lynis`, scripts de compilación de AUR) que las instalaciones de CachyOS no incluían `ID_LIKE=arch` en `/etc/os-release`, lo que rompía la detección automática basada únicamente en ese campo (véase [CachyOS/distribution#177](https://github.com/CachyOS/distribution/issues/177)). Por eso `glue` lista explícitamente los `ID` conocidos de las principales derivadas — como `cachyos` — en lugar de depender solo del fallback por `ID_LIKE`. Es exactamente el tipo de caso límite que este proyecto existe para absorber.

Una propiedad importante por diseño: si tu dialecto coincide con el backend nativo, `glue` no genera ningún alias. Por ejemplo, en CachyOS, si eliges `pacman` como dialecto, `pacman` sigue siendo exactamente el binario real — `glue` solo entra en acción para los comandos que no son nativos del sistema en el que estás.

## 📦 Backends soportados

| Familia | Detección (`ID` / `ID_LIKE`) | Backend nativo | Estado |
|---|---|---|---|
| Debian, Ubuntu, Mint, Pop!_OS | `debian` | `apt` / `apt-get` | ✅ v1 |
| Arch, Manjaro, EndeavourOS, **CachyOS** | `arch` | `pacman` (+ `yay`/`paru` opcional) | ✅ v1 |
| Fedora, RHEL, Rocky, AlmaLinux | `fedora` / `rhel` | `dnf` (fallback `yum`) | ✅ v1 |
| openSUSE, SLES | `suse` | `zypper` | ✅ v1 |
| Alpine | `alpine` | `apk` | 🔜 v1.1 |
| Void | `void` | `xbps` | 🔜 v1.1 |
| Gentoo | `gentoo` | `emerge` | 🧪 en estudio |
| NixOS | `nixos` | `nix` | ⚠️ ver Limitaciones |

## 🚀 Instalación

```bash
git clone https://github.com/axlfc/glue.git ~/.glue
echo 'source ~/.glue/glue.sh' >> ~/.bashrc
source ~/.bashrc
```

## 🛠️ Uso

```bash
# Se configura una vez: el dialecto es la sintaxis que ya llevas en la memoria muscular
glue config set-dialect apt

# A partir de aquí da igual el sistema en el que estés:
apt install neovim          # en Arch/CachyOS   → sudo pacman -S neovim
apt remove neovim           # en Fedora         → sudo dnf remove neovim
apt update && apt upgrade   # en openSUSE       → sudo zypper refresh && sudo zypper update
apt search ripgrep          # en cualquiera     → (sin sudo, no es una operación privilegiada)
```

También existe el propio comando `glue` como verbo neutro, por si prefieres no depender del "disfraz" de ningún gestor concreto:

```bash
glue install neovim
glue search ripgrep
```

> ⚠️ **Nota importante sobre `sudo`.** Escribe `apt install paquete`, no `sudo apt install paquete`. Las funciones de shell que define `glue` no son visibles para `sudo` (los alias/funciones de tu shell interactiva no se heredan en el subproceso que lanza `sudo`), así que es la propia función la que invoca `sudo` internamente cuando la operación lo requiere.

## 🔤 Tabla de equivalencias de comandos

| Acción | `apt` (dialecto) | `pacman` | `dnf` | `zypper` | `apk` |
|---|---|---|---|---|---|
| Instalar paquete | `install` | `-S` | `install` | `install` | `add` |
| Eliminar paquete | `remove` | `-R` | `remove` | `remove` | `del` |
| Eliminar + huérfanos | `autoremove` | `-Rns` | `autoremove` | `remove --clean-deps` | — (manual) |
| Refrescar índices | `update` | `-Sy` * | `makecache` | `refresh` | `update` |
| Actualizar sistema | `upgrade` | `-Syu` | `upgrade` | `update` | `upgrade` |
| Buscar paquete | `search` | `-Ss` | `search` | `search` | `search` |
| Info de un paquete | `show` | `-Si` | `info` | `info` | `info` |
| Listar instalados | `list --installed` | `-Q` | `list installed` | `packages --installed-only` | `list --installed` |
| Limpiar caché | `clean` | `-Sc` | `clean all` | `clean` | `cache clean` |

`*` `glue` nunca ejecuta el refresco de pacman (`-Sy`) de forma aislada: siempre lo encadena con la actualización (`-Syu`). Pacman desaconseja explícitamente las actualizaciones parciales (refrescar sin actualizar), ya que pueden dejar el sistema en un estado inconsistente.

Esta tabla es de referencia — algunas banderas exactas pueden variar entre versiones y conviene revisarlas al implementar cada backend.

## ⚙️ Configuración

```ini
# ~/.glue/config
GLUE_DIALECT=apt          # apt | pacman | dnf | zypper | apk
GLUE_BACKEND=auto         # auto | pacman | apt | dnf | zypper | apk (fuerza un backend)
GLUE_USE_AUR_HELPER=yay   # yay | paru | none (solo aplica si el backend es pacman)
GLUE_DRY_RUN=false        # true = muestra el comando real sin ejecutarlo
GLUE_VERBOSE=true         # true = imprime la traducción antes de ejecutar
```

## 📁 Estructura del proyecto

```
glue/
├── glue.sh              # Punto de entrada, se sourcea desde .bashrc
├── lib/
│   ├── detect.sh          # Parseo de /etc/os-release y resolución de backend
│   ├── dialects/           # Un archivo por sintaxis "de entrada"
│   │   ├── apt.sh
│   │   ├── pacman.sh
│   │   ├── dnf.sh
│   │   ├── zypper.sh
│   │   └── apk.sh
│   └── backends/            # Un archivo por gestor "de salida" real
│       ├── apt.sh
│       ├── pacman.sh
│       ├── dnf.sh
│       ├── zypper.sh
│       └── apk.sh
├── config/
│   └── glue.conf.example
├── install.sh
├── tests/                  # Suite con bats (Bash Automated Testing System)
└── README.md
```

## ⚠️ Limitaciones y consideraciones de diseño

- **Los nombres de paquete no siempre coinciden entre distros.** `glue` traduce el *verbo* (instalar, eliminar, buscar...), pero no puede garantizar que un paquete se llame igual en todos los repositorios (`python3-pip` en Debian, `python-pip` en Arch, por ejemplo). Para los paquetes populares suele coincidir, pero no es una garantía. Un mapeo de nombres es un desarrollo futuro razonable — ver Roadmap.
- **Actualizaciones parciales en Arch.** Ver la nota de la tabla de equivalencias: `glue` encadena siempre refresco + actualización en pacman para evitar este problema conocido.
- **Alcance de `sudo`.** Las funciones de `glue` invocan `sudo` internamente cuando hace falta; no funcionan si se antepone `sudo` manualmente delante del comando (ver la nota en Uso).
- **NixOS** sigue un paradigma declarativo (configuración inmutable) muy distinto al de instalación imperativa paquete a paquete, así que el mapeo de comandos no puede ser 1:1 y necesitaría un enfoque propio, no cubierto en la v1.
- **`glue` no sustituye conocer tu sistema.** Es una capa de comodidad para el día a día, no una abstracción perfecta — para operaciones delicadas (resolución de conflictos, downgrades, etc.) siempre conviene caer al comando nativo.

## 🔗 Proyectos relacionados

`glue` no es la primera herramienta que ataca este problema, y merece la pena decirlo con honestidad — de hecho, que existan varias es una buena señal de que el problema es real y resoluble:

- **[pacapt](https://github.com/icy/pacapt)** — wrapper en shell (56KB) que impone sintaxis de `pacman` sobre una decena de gestores (`apt`, `dnf`/`yum`, `zypper`, `homebrew`, `portage`...). Existe también **[pacaptr](https://github.com/rami3l/pacaptr)**, su reescritura en Rust.
- **[aptpac](https://github.com/Itai-Nelken/aptpac)** — justo la dirección contraria: sintaxis de `apt` sobre `pacman`, pensado para quien migra a Arch. Valida directamente el caso de uso que motiva este proyecto.
- **[upt](https://github.com/sigoden/upt)** — herramienta en Rust con su propio verbo unificado (`upt install`), detección de sistema operativo y la posibilidad de "renombrarse" para adoptar la sintaxis de otro gestor.

La diferencia de enfoque de `glue`: es bash puro (sin toolchain de compilación de por medio), permite mantener varios dialectos simultáneamente disponibles en vez de imponer uno fijo, y los propios comandos originales (`apt`, `pacman`...) siguen funcionando tal cual los conoces, en vez de tener que aprender un verbo nuevo.

## 🗺️ Roadmap

- [ ] v1.0 — Detección de SO + dialectos/backends para `apt`, `pacman`, `dnf`, `zypper`
- [ ] v1.1 — Soporte para `apk` (Alpine) y `xbps` (Void)
- [ ] v1.2 — Helpers de AUR (`yay`, `paru`) como backend opcional sobre `pacman`
- [ ] v1.3 — Modos globales `--dry-run` y `--verbose`
- [ ] v2.0 — Resolución de nombres de paquete entre distros (posible integración con [Repology](https://repology.org))
- [ ] Futuro — Gestores universales (`flatpak`, `snap`) como capa adicional

## 🤝 Contribuir

Las contribuciones son bienvenidas, especialmente para ampliar backends y dialectos, o para reportar equivalencias de comandos incorrectas. Antes de un PR grande, abre un issue para comentar el enfoque.

## 📄 Licencia

[GNU GPL v3](LICENSE)
