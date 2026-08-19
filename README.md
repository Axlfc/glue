# 🧩 glue

> Un único lenguaje de comandos para gestionar paquetes, sin importar en qué distribución de Linux estés.

![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-GNU_GPL_v3-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

**Estado:** ✅ v5.0 completado — Plataforma transversal completa con orquestación en clúster (`glue cluster`), auditoría de seguridad CVE (`glue audit`), autocuración del sistema (`glue repair`), proveedores universales, contenedores/SSH (`--target`), y gestión declarativa (`export`/`sync`).

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
│   • Hook Engine de Plugins (~/.config/glue/plugins/)                  │
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
| Debian, Ubuntu, Mint, Pop!_OS, Kali, Devuan | `debian` / `ubuntu` | `apt` / `apt-get` | ✅ v5.0 |
| Arch, Manjaro, EndeavourOS, CachyOS, Artix | `arch` | `pacman` (+ `yay`/`paru` AUR) | ✅ v5.0 |
| Fedora, RHEL, Rocky, AlmaLinux, CentOS | `fedora` / `rhel` | `dnf` (fallback `yum`) | ✅ v5.0 |
| openSUSE (Leap, Tumbleweed), SLES | `suse` | `zypper` | ✅ v5.0 |
| Alpine Linux | `alpine` | `apk` | ✅ v5.0 |
| Void Linux | `void` | `xbps` | ✅ v5.0 |

---

## 🚀 Guía de Instalación

### Instalación Automática (Recomendada)

```bash
git clone https://github.com/axlfc/glue.git ~/.glue
cd ~/.glue
./install.sh
source ~/.bashrc   # o source ~/.zshrc
```

### Instalación Manual

Añade la siguiente línea a tu archivo de configuración de shell (`~/.bashrc`, `~/.zshrc` o `~/.config/fish/config`):

```bash
source ~/.glue/glue.sh
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

### Comandos CLI de Configuración

```bash
glue config show              # Mostrar la configuración actual
glue config get dialect       # Consultar un valor
glue config set dialect pacman # Cambiar el dialecto activo
```

### Mantenimiento y Autocuración

```bash
glue audit                   # Auditar paquetes instalados buscando vulnerabilidades CVE
glue repair                  # Reparar dependencias rotas e índices desincronizados
glue clean                   # Limpiar la caché de todos los gestores
```

---

## 📖 Guía de Uso Completa

### 1. Invocación Interactiva por Dialecto

```bash
# Con dialecto APT configurado:
apt install python3-pip      # En Arch → sudo pacman -S python-pip (mapeo automático)
apt remove neovim            # En Fedora → sudo dnf remove neovim
apt update && apt upgrade    # En openSUSE → sudo zypper refresh && sudo zypper update
```

### 2. Comando Neutro `glue`

```bash
glue install ripgrep
glue search "editor de texto" --ai   # Búsqueda semántica inteligente
glue map build-essential              # Ver equivalencia de nombre entre distros
```

### 3. Banderas Globales y Proveedores (`--provider`, `--target`)

```bash
glue --dry-run apt install neovim
glue --provider=flatpak install org.gimp.GIMP
glue --provider=cargo install ripgrep
glue --target=docker:my_ubuntu install htop
glue --target=ssh://admin@remote-node install nginx
```

### 4. Flujo Declarativo y Clúster (`export`, `sync`, `rollback`, `cluster`)

```bash
glue export glue.lock        # Generar manifiesto declarativo del sistema
glue sync glue.lock          # Replicar el manifiesto en otra máquina
glue rollback                # Ver puntos de restauración (snapper / timeshift / tags)
glue cluster node-02         # Sincronizar estado entre nodos del clúster
glue webui 8080              # Iniciar dashboard web de monitoreo
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
- [ ] **v6.0** — Especificación y propuesta de arquitectura de próxima generación (Detalles a continuación)

---

## 🔮 Propuesta y Diseño Arquitectónico de `glue v6.0`

`glue v6.0` ampliará la plataforma hacia la observabilidad en tiempo real y la automatización avanzada:

1. **Monitoreo de System Calls vía eBPF (`glue trace`)**
   - Seguimiento mediante sondas eBPF de los archivos modificados y procesos creados durante la instalación de paquetes para auditar cambios en el sistema sin alterar binarios.

2. **Motor de Plugins WebAssembly (Wasm)**
   - Ejecución segura de plugins de extensión compilados a Wasm para extender traductores de backends sin dependencia del intérprete Bash.

3. **Agente Autónomo de Mantenimiento Desatendido**
   - Modo demonio para auto-parcheo en segundo plano con reversión automática en caso de fallo en comprobaciones de salud (`healthchecks`).

---

## 📄 Licencia

[GNU GPL v3](LICENSE)
