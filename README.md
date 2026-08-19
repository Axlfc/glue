# glue

> Un único lenguaje de comandos para gestionar paquetes, sin importar en qué distribución de Linux estés.

![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-GNU_GPL_v3-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

**Estado:** ✅ v2.0 completado — Mapeo inteligente de paquetes entre distros + Integración con Repology + Soporte de flags globales y AUR helpers.

---

## 🧩 ¿Qué es `glue`?

`glue` es una capa de abstracción, escrita en bash puro, que se sitúa entre tú y el gestor de paquetes nativo de cada distribución Linux. Su objetivo es simple: que nunca más tengas que recordar qué comando usa cada sistema ni cómo se llama exactamente un paquete en cada repositorio.

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

El resultado es memoria muscular rota constantemente: `apt install` no existe en Arch, `pacman -S` no existe en Debian, y los nombres de paquete difieren (`python3-pip` en Ubuntu vs `python-pip` en Arch; `build-essential` vs `base-devel`). `glue` resuelve tanto la sintaxis de comandos como la equivalencia de nombres.

## ⚙️ Cómo funciona

1. **Detección del sistema.** Al cargar `glue`, se parsean los campos `ID` e `ID_LIKE` de `/etc/os-release` para identificar tanto la distribución exacta como su familia.
2. **Resolución del backend.** Con la distro identificada, `glue` comprueba qué gestor de paquetes nativo está realmente disponible en el `$PATH` (incluyendo helpers de AUR como `yay` o `paru`).
3. **Mapeo inteligente de nombres de paquete (v2.0).** `glue` traduce automáticamente el nombre del paquete entre repositorios (vía diccionario local estático o mediante consulta en tiempo real con caché a la API de **Repology**).
4. **Elección de dialecto.** Configuras una vez qué sintaxis quieres usar (tu "dialecto": `apt`, `pacman`, `dnf`...).
5. **Traducción y ejecución.** `glue` intercepta los verbos y flags (`install`, `remove`, `update`, `search`...) y los traduce a la invocación real del backend nativo.

```
┌──────────────┐     ┌──────────────────┐     ┌───────────────────┐     ┌──────────────────┐
│   Tú          │ --> │  Tu dialecto      │ --> │  Motor de glue    │ --> │  Backend nativo   │
│ "apt install" │     │  (sintaxis apt)   │     │ (Mapeo de paquete │     │ (pacman, dnf,     │
│               │     │                   │     │  y traducción)    │     │  zypper, apk...)  │
└──────────────┘     └──────────────────┘     └───────────────────┘     └──────────────────┘
```

## 📦 Backends soportados

| Familia | Detección (`ID` / `ID_LIKE`) | Backend nativo | Estado |
|---|---|---|---|
| Debian, Ubuntu, Mint, Pop!_OS, Kali, Devuan | `debian` / `ubuntu` | `apt` / `apt-get` | ✅ v2.0 |
| Arch, Manjaro, EndeavourOS, **CachyOS**, Artix | `arch` | `pacman` (+ `yay`/`paru` opcional) | ✅ v2.0 |
| Fedora, RHEL, Rocky, AlmaLinux, CentOS | `fedora` / `rhel` | `dnf` (fallback `yum`) | ✅ v2.0 |
| openSUSE, SLES | `suse` | `zypper` | ✅ v2.0 |
| Alpine | `alpine` | `apk` | ✅ v2.0 |
| Void | `void` | `xbps` | ✅ v2.0 |

## 🛠️ Uso

```bash
# Se configura el dialecto habitual:
glue config set dialect apt

# Ejecución normal:
apt install python3-pip     # En Arch → sudo pacman -S python-pip (mapeo automático de nombre)
apt install build-essential # En Fedora → sudo dnf install gcc-c++ (mapeo automático)

# Banderas globales instantáneas:
glue --dry-run apt install neovim
glue --verbose --backend=apk install ripgrep

# Ver la equivalencia de un paquete entre todas las distros:
glue map fd
```

## 🔤 Tabla de equivalencias de comandos

| Acción | `apt` (dialecto) | `pacman` | `dnf` | `zypper` | `apk` | `xbps` |
|---|---|---|---|---|---|---|
| Instalar | `install` | `-S` | `install` | `install` | `add` | `-S` |
| Eliminar | `remove` | `-R` | `remove` | `remove` | `del` | `remove` |
| Huérfanos | `autoremove` | `-Rns` | `autoremove` | `remove --clean-deps` | `del` | `-o` |
| Índices | `update` | `-Sy` | `makecache` | `refresh` | `update` | `-S` |
| Actualizar | `upgrade` | `-Syu` | `upgrade` | `update` | `upgrade` | `-su` |
| Buscar | `search` | `-Ss` | `search` | `search` | `search` | `-Rs` |
| Info | `show` | `-Si` | `info` | `info` | `info` | `-S` |
| Lista | `list --installed` | `-Q` | `list installed` | `packages --installed-only` | `list --installed` | `-l` |
| Limpiar | `clean` | `-Sc` | `clean all` | `clean` | `cache clean` | `-O` |

## 🗺️ Roadmap de versiones

- [x] **v1.0** — Detección de SO + dialectos/backends para `apt`, `pacman`, `dnf`, `zypper`, `apk`, `xbps`
- [x] **v1.1** — Integración extendida con helpers de AUR (`yay`, `paru`, `auto`)
- [x] **v1.2** — Banderas CLI globales (`--dry-run`, `--verbose`, `--backend=<name>`)
- [x] **v2.0** — Mapeo inteligente de nombres de paquetes entre distribuciones (Local database + Repology API con caché local)
- [ ] **v3.0** — Especificación de Arquitectura de Próxima Generación (Diseño detallado a continuación)

---

## 🔮 Diseño Arquitectónico de `glue v3.0`

`glue v3.0` expandirá las capacidades de la herramienta convirtiéndola en un gestor universal de entrono heterogéneo.

### 📐 Principales Pilares de v3.0

1. **Gestores de Paquetes Universales (`flatpak`, `snap`, `appimage`, `nix`)**
   - Introducción de modificadores de alcance o proveedores explícitos:
     ```bash
     glue install --provider=flatpak org.gimp.GIMP
     glue install --provider=snap code
     ```
   - Si un paquete no existe en los repositorios nativos del sistema, `glue` ofrecerá un fallback automático hacia Flatpak / Snap si están disponibles.

2. **Ejecución Remota y en Contenedores (`--target`)**
   - Ejecución de comandos de paquetes sobre contenedores Docker/Podman o máquinas remotas mediante SSH sin necesidad de instalar `glue` en el destino:
     ```bash
     glue --target=docker:my_ubuntu_container install neovim
     glue --target=ssh://user@remote-host install htop
     ```

3. **Arquitectura Modular de Plugins (`lib/plugins/`)**
   - Sistema de hooks pre/post instalación para ejecutar acciones automatizadas (p. ej., reiniciar servicios, limpiar dependencias, notificaciones).
   - Extensibilidad mediante scripts `.sh` colocados en `~/.config/glue/plugins/`.

4. **Detección e Integración de Lenguajes y Módulos (`pip`, `cargo`, `npm`, `gem`)**
   - Soporte opcional para paquetes de lenguajes de programación mediante dialectos unificados:
     ```bash
     glue --provider=cargo install ripgrep
     glue --provider=pip install requests
     ```

---

## 📄 Licencia

[GNU GPL v3](LICENSE)
