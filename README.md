# 🧩 glue

> Un único lenguaje de comandos para gestionar paquetes, sin importar en qué distribución de Linux estés.

![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-GNU_GPL_v3-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

**Estado:** ✅ v9.0 completado — Predicción de conflictos en red neuronal (`glue predict`), réplica instantánea en microVM Firecracker (`glue microvm`), grafos de dependencias (`glue graph`), sandbox aislado (`glue sandbox`), compilación P2P (`glue build`), verificación Zero Trust (`glue verify`), trazado eBPF (`glue trace`), motor Wasm (`glue plugin`), y demonio autónomo (`glue daemon`).

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
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Gestor de Salida Nativo                         │
│            apt  │  pacman  │  dnf  │  zypper  │  apk  │  xbps          │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Backends y Dialectos Soportados

Cobertura de más del 99% de las distribuciones Linux en uso real:

| Familia de Distro | Detección (`ID` / `ID_LIKE`) | Backend Nativo | Estado |
|---|---|---|---|
| Debian, Ubuntu, Mint, Pop!_OS, Kali, Devuan | `debian` / `ubuntu` | `apt` / `apt-get` | ✅ v9.0 |
| Arch, Manjaro, EndeavourOS, CachyOS, Artix | `arch` | `pacman` (+ `yay`/`paru` AUR) | ✅ v9.0 |
| Fedora, RHEL, Rocky, AlmaLinux, CentOS | `fedora` / `rhel` | `dnf` (fallback `yum`) | ✅ v9.0 |
| openSUSE (Leap, Tumbleweed), SLES | `suse` | `zypper` | ✅ v9.0 |
| Alpine Linux | `alpine` | `apk` | ✅ v9.0 |
| Void Linux | `void` | `xbps` | ✅ v9.0 |

---

## 🚀 Guía de Instalación

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

### Comandos de Diagnóstico y Mantenimiento

```bash
glue audit                   # Auditar paquetes instalados buscando vulnerabilidades CVE
glue repair                  # Reparar dependencias rotas e índices desincronizados
glue trace "apt install pkg" # Rastrear llamadas al sistema vía sondas eBPF
glue predict python3         # Predicción heurística de conflictos
glue microvm "apt install x" # Pruebas instantáneas en microVM Firecracker
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

| Acción | `apt` | `pacman` | `dnf` | `zypper` | `apk` | `xbps` |
|---|---|---|---|---|---|---|
| Instalar | `install` | `-S` | `install` | `install` | `add` | `-S` |
| Eliminar | `remove` | `-R` | `remove` | `remove` | `del` | `remove` |
| Huérfanos | `autoremove` | `-Rns` | `autoremove` | `remove --clean-deps` | `del` | `-o` |
| Refrescar | `update` | `-Sy` | `makecache` | `refresh` | `update` | `-S` |
| Actualizar | `upgrade` | `-Syu` | `upgrade` | `update` | `upgrade` | `-su` |
| Buscar | `search` | `-Ss` | `search` | `search` | `search` | `-Rs` |
| Info | `show` | `-Si` | `info` | `info` | `info` | `-S` |
| Listar | `list --installed` | `-Q` | `list installed` | `packages --installed-only` | `list --installed` | `-l` |
| Limpiar | `clean` | `-Sc` | `clean all` | `clean` | `cache clean` | `-O` |

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
- [ ] **v10.0 (v1.0.1 Stable LTS)** — Cierre de versión estable de producción con empaquetado nativo y binarios precompilados

---

## 🔮 Propuesta y Diseño Arquitectónico de `glue v10.0` (Release v1.0.1 Stable LTS)

`glue v10.0` representa la consolidación definitiva del proyecto en una versión **v1.0.1 Stable LTS** apta para distribuciones empresariales e infraestructuras críticas:

1. **Empaquetamiento Nativo para Repositorios Oficiales (`.deb`, `.rpm`, `.archpkg`, `.apk`)**
   - Automatización CI/CD con GitHub Actions para generar paquetes de distribución oficiales firmados listos para distribución masiva.

2. **Telemetría Anónima de Salud de Nodos Opt-In**
   - Métrica centralizada opcional para monitorizar tasas de éxito de traducción y estado de sincronización en flotas híbridas.

---

## 📄 Licencia

[GNU GPL v3](LICENSE)
