# glue

> Un único lenguaje de comandos para gestionar paquetes, sin importar en qué distribución de Linux estés.

![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-GNU_GPL_v3-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

**Estado:** ✅ v1.0 disponible — Implementación completa de la capa de abstracción en `bash`.

---

## 🧩 ¿Qué es `glue`?

`glue` es una capa de abstracción, escrita en bash puro, que se sitúa entre tú y el gestor de paquetes nativo de cada distribución Linux. Su objetivo es simple: que nunca más tengas que recordar qué comando usa cada sistema.

El nombre no es casual: `glue` (pegamento) es literalmente lo que hace — pega tu forma de trabajar habitual sobre cualquier sistema, en lugar de obligarte a adaptarte tú a cada uno.

## 🚧 El problema

Cada familia de distribuciones trae su propio gestor de paquetes, con su propia sintaxis:

- **Debian, Ubuntu, Mint, Pop!_OS, Devuan, Kali, Elementary** → `apt`, `apt-get`, `dpkg`
- **Arch, Manjaro, EndeavourOS, CachyOS, Artix, Garuda** → `pacman` (y helpers de AUR como `yay` o `paru`)
- **Fedora, RHEL, Rocky, AlmaLinux, CentOS, Nobara** → `dnf` (`yum` en versiones antiguas)
- **openSUSE (Leap, Tumbleweed), SLES** → `zypper`
- **Alpine Linux** → `apk`
- **Void Linux** → `xbps`
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
  void)                              GLUE_BACKEND="xbps"   ;;
  *)
    # Fallback para derivadas no listadas explícitamente
    case "$ID_LIKE" in
      *arch*)           GLUE_BACKEND="pacman" ;;
      *debian*|*ubuntu*) GLUE_BACKEND="apt"   ;;
      *fedora*|*rhel*)  GLUE_BACKEND="dnf"    ;;
      *suse*)           GLUE_BACKEND="zypper" ;;
      *alpine*)         GLUE_BACKEND="apk"    ;;
      *void*)           GLUE_BACKEND="xbps"   ;;
      *)                GLUE_BACKEND=""       ;; # no detectado
    esac
    ;;
esac
```

> **Nota real:** confiar solo en `ID_LIKE` no siempre es suficiente. Durante 2025 y principios de 2026 se reportó en varios proyectos (`topgrade`, `lynis`, scripts de compilación de AUR) que las instalaciones de CachyOS no incluían `ID_LIKE=arch` en `/etc/os-release`, lo que rompía la detección basada únicamente en ese campo. Por eso `glue` lista explícitamente los `ID` conocidos de las principales derivadas — como `cachyos` — en lugar de depender solo del fallback por `ID_LIKE`.

Una propiedad importante por diseño: si tu dialecto coincide con el backend nativo, `glue` no genera ningún alias. Por ejemplo, en CachyOS, si eliges `pacman` como dialecto, `pacman` sigue siendo exactamente el binario real — `glue` solo entra en acción para los comandos que no son nativos del sistema en el que estás.

## 📦 Backends soportados

Cobertura de más del 99% de las distribuciones Linux en uso real:

| Familia | Detección (`ID` / `ID_LIKE`) | Backend nativo | Estado |
|---|---|---|---|
| Debian, Ubuntu, Mint, Pop!_OS, Kali, Devuan | `debian` / `ubuntu` | `apt` / `apt-get` | ✅ v1.0 |
| Arch, Manjaro, EndeavourOS, **CachyOS**, Artix | `arch` | `pacman` (+ `yay`/`paru` opcional) | ✅ v1.0 |
| Fedora, RHEL, Rocky, AlmaLinux, CentOS | `fedora` / `rhel` | `dnf` (fallback `yum`) | ✅ v1.0 |
| openSUSE, SLES | `suse` | `zypper` | ✅ v1.0 |
| Alpine | `alpine` | `apk` | ✅ v1.0 |
| Void | `void` | `xbps` | ✅ v1.0 |
| Gentoo | `gentoo` | `emerge` | 🧪 en estudio |
| NixOS | `nixos` | `nix` | ⚠️ ver Limitaciones |

## 🚀 Instalación

```bash
git clone https://github.com/axlfc/glue.git ~/.glue
echo 'source ~/.glue/glue.sh' >> ~/.bashrc
source ~/.bashrc
```

O ejecutando el instalador incluido:

```bash
./install.sh
```

## 🛠️ Uso

```bash
# Se configura una vez: el dialecto es la sintaxis que ya llevas en la memoria muscular
glue config set dialect apt

# A partir de aquí da igual el sistema en el que estés:
apt install neovim          # en Arch/CachyOS   → sudo pacman -S neovim
apt remove neovim           # en Fedora         → sudo dnf remove neovim
apt update && apt upgrade   # en openSUSE       → sudo zypper refresh && sudo zypper update
apt search ripgrep          # en cualquiera     → (sin sudo, no es una operación privileged)
```

También existe el propio comando `glue` como verbo neutro:

```bash
glue install neovim
glue search ripgrep
```

> ⚠️ **Nota importante sobre `sudo`.** Escribe `apt install paquete`, no `sudo apt install paquete`. Las funciones de shell que define `glue` no son visibles para `sudo` (los alias/funciones de tu shell interactiva no se heredan en el subproceso que lanza `sudo`), así que es la propia función la que invoca `sudo` internamente cuando la operación lo requiere.

## 🔤 Tabla de equivalencias de comandos

| Acción | `apt` (dialecto) | `pacman` | `dnf` | `zypper` | `apk` | `xbps` |
|---|---|---|---|---|---|---|
| Instalar paquete | `install` | `-S` | `install` | `install` | `add` | `-S` |
| Eliminar paquete | `remove` | `-R` | `remove` | `remove` | `del` | `remove` |
| Eliminar + huérfanos | `autoremove` | `-Rns` | `autoremove` | `remove --clean-deps` | `del` | `-o` |
| Refrescar índices | `update` | `-Sy` * | `makecache` | `refresh` | `update` | `-S` |
| Actualizar sistema | `upgrade` | `-Syu` | `upgrade` | `update` | `upgrade` | `-su` |
| Buscar paquete | `search` | `-Ss` | `search` | `search` | `search` | `-Rs` |
| Info de un paquete | `show` | `-Si` | `info` | `info` | `info` | `-S` |
| Listar instalados | `list --installed` | `-Q` | `list installed` | `packages --installed-only` | `list --installed` | `-l` |
| Limpiar caché | `clean` | `-Sc` | `clean all` | `clean` | `cache clean` | `-O` |

`*` `glue` nunca ejecuta el refresco de pacman (`-Sy`) de forma aislada: siempre lo encadena con la actualización (`-Syu`).

## ⚙️ Configuración

```ini
# ~/.config/glue/config o ~/.glue/config
GLUE_DIALECT=apt          # apt | pacman | dnf | zypper | apk | xbps
GLUE_BACKEND=auto         # auto | pacman | apt | dnf | zypper | apk | xbps (fuerza un backend)
GLUE_USE_AUR_HELPER=yay   # yay | paru | none (solo aplica si el backend es pacman)
GLUE_DRY_RUN=false        # true = muestra el comando real sin ejecutarlo
GLUE_VERBOSE=true         # true = imprime la traducción antes de ejecutar
```

## 📁 Estructura del proyecto

```
glue/
├── glue.sh              # Punto de entrada, se sourcea desde .bashrc/.zshrc
├── lib/
│   ├── config.sh        # Gestión de configuración
│   ├── detect.sh        # Parseo de /etc/os-release y resolución de backend
│   ├── core.sh          # Motor de ejecución, dry-run, verbose y sudo
│   ├── dialects/        # Un archivo por sintaxis "de entrada"
│   │   ├── apt.sh
│   │   ├── pacman.sh
│   │   ├── dnf.sh
│   │   ├── zypper.sh
│   │   ├── apk.sh
│   │   └── xbps.sh
│   └── backends/        # Un archivo por gestor "de salida" real
│       ├── apt.sh
│       ├── pacman.sh
│       ├── dnf.sh
│       ├── zypper.sh
│       ├── apk.sh
│       └── xbps.sh
├── config/
│   └── glue.conf.example
├── install.sh           # Instalador automático
├── tests/               # Suite de tests (`tests/test_runner.sh`)
└── README.md
```

## 🗺️ Roadmap

- [x] v1.0 — Detección de SO + dialectos/backends para `apt`, `pacman`, `dnf`, `zypper`, `apk`, `xbps`
- [ ] v1.1 — Helpers de AUR (`yay`, `paru`) en pacman con flags extendidos
- [ ] v1.2 — Modos globales `--dry-run` y `--verbose` vía CLI flags
- [ ] v2.0 — Resolución de nombres de paquete entre distros (posible integración con Repology)

## 📄 Licencia

[GNU GPL v3](LICENSE)
