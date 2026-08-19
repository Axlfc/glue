# 🧩 glue (v1.0.1 Stable LTS)

> Un único lenguaje de comandos para gestionar paquetes, sin importar en qué distribución de Linux estés.

![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-GNU_GPL_v3-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)
![Release](https://img.shields.io/badge/version-v1.0.1_LTS-green)

**Estado:** ✅ v1.0.1 Stable LTS — Lanzamiento de producción oficial con soporte completo transversal para todas las familias Linux (Debian, Arch, Fedora, openSUSE, Alpine, Void, Gentoo, Solus, NixOS, etc.), proveedores universales, contenedores/SSH, manifiestos declarativos, observabilidad eBPF, búsqueda IA y telemetría de flota.

---

## 📋 Visión General del Proyecto

`glue` es una capa de abstracción escrita en Bash puro que se sitúa entre el usuario y los gestores de paquetes nativos de cualquier distribución Linux. Elimina la sobrecarga de memoria muscular convirtiendo la sintaxis de tu dialecto preferido (`apt`, `pacman`, `dnf`, `zypper`, `apk`, `xbps`) a los comandos exactos del sistema en ejecución.

### 📐 Arquitectura del Sistema

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Capa de Entrada (Dialectos)                      │
│            apt  │  pacman  │  dnf  │  zypper  │  apk  │  xbps          │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Motor Central (lib/core.sh)                      │
│   • Global Flags (--dry-run, --verbose, --backend)                      │
│   • Proveedores Universales (--provider=flatpak|snap|pip|cargo|npm)    │
│   • Ejecución en Contenedores & SSH (--target=docker|podman|ssh)       │
│   • Mapeo Inteligente de Paquetes & Repology API (lib/pkgmap.sh)        │
│   • Predicción Heurística de Conflictos & MicroVM Sandbox               │
│   • Grafos de Dependencias & Entornos Sandbox (`glue graph`/`sandbox`)  │
│   • Hook Engine de Plugins & Wasm Engine (~/.config/glue/plugins/)     │
│   • Observabilidad eBPF & Demonio Autónomo (`glue trace` / `daemon`)   │
│   • Compilación P2P Distribuida & Verificación Zero Trust              │
│   • Telemetría Anónima de Salud de Nodos Opt-In (`glue telemetry`)     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Gestor de Salida Nativo                         │
│   apt │ pacman │ dnf │ zypper │ apk │ xbps │ emerge │ eopkg │ nix ...  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Matriz de Soporte Transversal de Distribuciones Linux

`glue` ofrece soporte completo para todas las familias de distribuciones Linux reconocidas:

### 1. Debian y Derivados

| Distribución | `ID` habitual | `ID_LIKE` | Package Manager | Estado |
|---|---|---|---|---|
| Debian | `debian` | — | `apt` / `dpkg` | ✅ Soportado |
| Ubuntu (Kubuntu, Xubuntu, Lubuntu, MATE, Studio, Budgie, Cinnamon) | `ubuntu` | `debian` | `apt` / `dpkg` | ✅ Soportado |
| Linux Mint / LMDE | `linuxmint` / `lmde` | `ubuntu debian` | `apt` / `dpkg` | ✅ Soportado |
| Pop!_OS | `pop` / `ubuntu` | `ubuntu debian` | `apt` / `dpkg` | ✅ Soportado |
| elementary OS | `elementary` | `ubuntu debian` | `apt` / `dpkg` | ✅ Soportado |
| Zorin OS | `zorin` | `ubuntu debian` | `apt` / `dpkg` | ✅ Soportado |
| KDE neon | `neon` | `ubuntu debian` | `apt` / `dpkg` | ✅ Soportado |
| PEppermint OS / MX Linux / antiX / Sparky | `peppermint` / `mx` | `debian` | `apt` / `dpkg` | ✅ Soportado |
| Devuan / Kali Linux / Parrot OS / Tails | `devuan` / `kali` | `debian` | `apt` / `dpkg` | ✅ Soportado |
| PureOS / Trisquel / BunsenLabs / Deepin | `pureos` / `deepin` | `debian` | `apt` / `dpkg` | ✅ Soportado |
| Raspbian / Raspberry Pi OS / DietPi / Armbian | `raspbian` / `armbian` | `debian` | `apt` / `dpkg` | ✅ Soportado |
| Proxmox VE / OpenMediaVault / Whonix | `proxmox` | `debian` | `apt` / `dpkg` | ✅ Soportado |

### 2. Red Hat, Fedora y RPM

| Distribución | `ID` habitual | `ID_LIKE` | Package Manager | Estado |
|---|---|---|---|---|
| Fedora / Silverblue / Kinoite / CoreOS | `fedora` | `rhel fedora` | `dnf` / `rpm-ostree` | ✅ Soportado |
| Red Hat Enterprise Linux (RHEL) / SAP | `rhel` | `fedora` | `dnf` / `rpm` | ✅ Soportado |
| CentOS Stream / CentOS Linux | `centos` | `rhel fedora` | `dnf` / `yum` | ✅ Soportado |
| Rocky Linux / AlmaLinux / Kitten | `rocky` / `almalinux` | `rhel fedora` | `dnf` / `rpm` | ✅ Soportado |
| Oracle Linux / Amazon Linux 2023 / AL2 | `ol` / `amzn` | `fedora` / `rhel` | `dnf` / `yum` | ✅ Soportado |
| Qubes OS / Scientific Linux / ClearOS | `qubes` | `fedora` | `dnf` / `rpm` | ✅ Soportado |
| Anolis OS / EuroLinux / Miracle Linux | `anolis` | `rhel fedora` | `dnf` / `rpm` | ✅ Soportado |

### 3. Arch y Derivados

| Distribución | `ID` habitual | `ID_LIKE` | Package Manager | Estado |
|---|---|---|---|---|
| Arch Linux | `arch` | — | `pacman` | ✅ Soportado |
| Manjaro | `manjaro` | `arch` | `pacman` | ✅ Soportado |
| EndeavourOS / Garuda / ArcoLinux | `endeavouros` / `garuda` | `arch` | `pacman` | ✅ Soportado |
| CachyOS | `cachyos` | `arch` | `pacman` | ✅ Soportado |
| Artix Linux / BlackArch / Parabola | `artix` / `blackarch` | `arch` | `pacman` | ✅ Soportado |
| SteamOS 3 / ChimeraOS / HoloISO | `steamos` / `chimeraos` | `arch` | `pacman` | ✅ Soportado |
| Archcraft / RebornOS / Mabox / BigLinux | `archcraft` | `arch` | `pacman` | ✅ Soportado |

### 4. SUSE y RPM Alternativos

| Distribución | `ID` habitual | `ID_LIKE` | Package Manager | Estado |
|---|---|---|---|---|
| openSUSE Tumbleweed / Leap | `opensuse-tumbleweed` | `suse opensuse` | `zypper` / `rpm` | ✅ Soportado |
| openSUSE MicroOS / Aeon | `opensuse-microos` | `suse opensuse` | `zypper` / `transactional-update` | ✅ Soportado |
| SUSE Linux Enterprise (SLES / SL-Micro) | `sles` / `sl-micro` | `suse` | `zypper` / `rpm` | ✅ Soportado |
| GeckoLinux | `geckolinux` | `opensuse suse` | `zypper` / `rpm` | ✅ Soportado |

### 5. Independientes y Especializados

| Distribución | `ID` habitual | Package Manager | Estado |
|---|---|---|---|
| Gentoo / Funtoo / Calculate | `gentoo` | `emerge` / Portage | ✅ Soportado |
| Void Linux | `void` | `xbps` | ✅ Soportado |
| Alpine Linux / postmarketOS | `alpine` | `apk` | ✅ Soportado |
| Solus | `solus` | `eopkg` | ✅ Soportado |
| NixOS | `nixos` | `nix` | ✅ Soportado |
| Guix System | `guix` | `guix` | ✅ Soportado |
| Slackware / Salix / Porteux | `slackware` | `slackpkg` / `pkgtools` | ✅ Soportado |
| Clear Linux | `clear-linux-os` | `swupd` | ✅ Soportado |

---

## 🚀 Guía de Instalación

### Instalación Automática (Recomendada)

```bash
git clone https://github.com/axlfc/glue.git ~/.glue
cd ~/.glue
./install.sh
source ~/.bashrc   # o source ~/.zshrc
```

---

## 🔧 Configuración y Mantenimiento

### Archivo de Configuración (`~/.config/glue/config`)

```ini
GLUE_DIALECT=apt          # apt | pacman | dnf | zypper | apk | xbps
GLUE_BACKEND=auto         # auto | pacman | apt | dnf | zypper | apk | xbps
GLUE_USE_AUR_HELPER=auto   # yay | paru | auto | none
GLUE_DRY_RUN=false        # true | false
GLUE_VERBOSE=true         # true | false
```

### Comandos de Mantenimiento y Diagnóstico

```bash
glue audit                   # Auditar paquetes instalados buscando vulnerabilidades CVE
glue repair                  # Reparar dependencias rotas e índices desincronizados
glue trace "apt install pkg" # Rastrear llamadas al sistema vía sondas eBPF
glue verify glue.lock        # Verificar firma criptográfica de manifiestos Zero Trust
glue telemetry status        # Estado de telemetría anónima de flota
glue daemon start            # Iniciar demonio de mantenimiento autónomo
glue clean                   # Limpiar la caché de todos los gestores
```

---

## 📖 Guía de Uso Completa

```bash
# Dialecto nativo habitual:
apt install python3-pip

# Búsqueda semántica inteligente con IA:
glue search --ai "editor de texto"

# Proveedores y targets:
glue --provider=flatpak install org.gimp.GIMP
glue --target=docker:container_ubuntu install neovim

# Compilación distribuida P2P, firmas y sandbox:
glue build neovim-git
glue verify glue.lock
glue predict neovim
glue microvm "apt install neovim"

# Gestión declarativa y clúster:
glue export glue.lock
glue sync glue.lock
glue cluster node-02
glue webui 8080
```

---

## 🔤 Tabla Transversal de Equivalencias de Comandos

| Acción | `apt` | `pacman` | `dnf` | `zypper` | `apk` | `xbps` | `emerge` | `eopkg` | `nix` |
|---|---|---|---|---|---|---|---|---|---|
| Instalar | `install` | `-S` | `install` | `install` | `add` | `-S` | `emerge` | `install` | `nix-env -iA` |
| Eliminar | `remove` | `-R` | `remove` | `remove` | `del` | `remove` | `emerge --unmerge` | `remove` | `nix-env -e` |
| Huérfanos | `autoremove` | `-Rns` | `autoremove` | `remove --clean-deps` | `del` | `-o` | `emerge --depclean` | `remove-orphans` | `nix-store --gc` |
| Refrescar | `update` | `-Sy` | `makecache` | `refresh` | `update` | `-S` | `emaint sync` | `update-repo` | `nix-channel --update` |
| Actualizar | `upgrade` | `-Syu` | `upgrade` | `update` | `upgrade` | `-su` | `emerge -u @world` | `upgrade` | `nix-env -u` |
| Buscar | `search` | `-Ss` | `search` | `search` | `search` | `-Rs` | `emerge --search` | `search` | `nix-env -qaP` |
| Info | `show` | `-Si` | `info` | `info` | `info` | `-S` | `emerge --info` | `info` | `nix-env -qaP --description` |
| Listar | `list --installed` | `-Q` | `list installed` | `packages --installed-only` | `list --installed` | `-l` | `qlist -I` | `list-installed` | `nix-env -q` |
| Limpiar | `clean` | `-Sc` | `clean all` | `clean` | `cache clean` | `-O` | `eclean distfiles` | `delete-cache` | `nix-store --gc` |

---

## 🗺️ Roadmap de Versiones

- [x] **v1.0** — Detección de SO + dialectos/backends para `apt`, `pacman`, `dnf`, `zypper`, `apk`, `xbps`
- [x] **v1.1** — Integración extendida con helpers de AUR (`yay`, `paru`, `auto`)
- [x] **v1.2** — Banderas CLI globales (`--dry-run`, `--verbose`, `--backend=<name>`)
- [x] **v2.0** — Mapeo inteligente de nombres de paquetes entre distribuciones (Database local + Repology API con caché)
- [x] **v3.0** — Proveedores universales (`flatpak`, `snap`, `pip`, `cargo`, `npm`), ejecuciones en contenedores/SSH (`--target`), y sistema de hooks de plugins
- [x] **v4.0** — Manifiesto declarativo (`export`/`sync`), snapshot rollback, búsqueda IA semántica y servidor WebUI dashboard
- [x] **v5.0** — Orquestación en clúster (`glue cluster`), auditoría de seguridad CVE (`glue audit`), autocuración (`glue repair`)
- [x] **v6.0** — Monitoreo eBPF (`glue trace`), motor Wasm (`glue plugin`), demonio autónomo (`glue daemon`)
- [x] **v7.0** — Compilación P2P distribuida (`glue build`), verificación criptográfica Zero Trust (`glue verify`)
- [x] **v8.0** — Grafos de dependencias multi-distro (`glue graph`), espacios de nombres sandbox efímeros (`glue sandbox`)
- [x] **v9.0** — Predicción heurística de conflictos (`glue predict`), aislamiento en microVM Firecracker (`glue microvm`)
- [x] **v1.0.1 LTS** — Lanzamiento Estable Producción con telemetría opt-in y empaquetamiento estandarizado

---

## 📄 Licencia

[GNU GPL v3](LICENSE)
