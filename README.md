# glue

> Un único lenguaje de comandos para gestionar paquetes, sin importar en qué distribución de Linux estés.

![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-GNU_GPL_v3-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

**Estado:** ✅ v3.0 completado — Proveedores universales y de lenguajes (`flatpak`, `snap`, `pip`, `cargo`, `npm`), ejecuciones remotas/contenedores (`--target`), y motor de plugins de hooks.

---

## 🧩 ¿Qué es `glue`?

`glue` es una capa de abstracción, escrita en bash puro, que se sitúa entre tú y el gestor de paquetes nativo de cada distribución Linux. Su objetivo es simple: que nunca más tengas que recordar qué comando usa cada sistema ni cómo se llama exactamente un paquete en cada repositorio.

El nombre no es casual: `glue` (pegamento) es literalmente lo que hace — pega tu forma de trabajar habitual sobre cualquier sistema, en lugar de obligarte a adaptarte tú a cada uno.

## ⚙️ Cómo funciona

1. **Detección del sistema.** Se parsean los campos `ID` e `ID_LIKE` de `/etc/os-release` para identificar tanto la distribución exacta como su familia.
2. **Resolución del backend/proveedor.** `glue` comprueba qué gestor nativo está disponible, o aplica el proveedor solicitado (`--provider=flatpak|snap|pip|cargo|npm`).
3. **Mapeo inteligente (v2.0).** Traduce automáticamente el nombre del paquete entre repositorios (vía diccionario local estático o mediante consulta con caché a **Repology**).
4. **Ejecución remota/contenedor (`--target`).** Opcionalmente envuelve y redirige la invocación hacia contenedores Docker/Podman o servidores remotos vía SSH.
5. **Motor de plugins.** Ejecuta hooks de preconmutación y postconmutación (`pre` y `post`) definidos por el usuario en `~/.config/glue/plugins/`.

```
┌──────────────┐     ┌──────────────────┐     ┌───────────────────┐     ┌──────────────────┐
│   Tú          │ --> │  Tu dialecto      │ --> │  Motor de glue    │ --> │  Backend nativo   │
│ "apt install" │     │  (sintaxis apt)   │     │ (Mapeo, Proveedor │     │ (pacman, dnf,     │
│               │     │                   │     │  Target y Hooks)  │     │  flatpak, docker) │
└──────────────┘     └──────────────────┘     └───────────────────┘     └──────────────────┘
```

## 🛠️ Uso y Ejemplos v3.0

```bash
# Configuración inicial del dialecto preferido:
glue config set dialect apt

# Uso universal con el dialecto habitual:
apt install python3-pip

# Banderas de proveedores universales y de lenguajes (v3.0):
glue --provider=flatpak install org.gimp.GIMP
glue --provider=snap install code
glue --provider=cargo install ripgrep
glue --provider=pip install requests

# Ejecución sobre contenedores o destinos remotos SSH (v3.0):
glue --target=docker:container_ubuntu install neovim
glue --target=ssh://user@remote-server install htop
```

## 🗺️ Roadmap de versiones

- [x] **v1.0** — Detección de SO + dialectos/backends para `apt`, `pacman`, `dnf`, `zypper`, `apk`, `xbps`
- [x] **v1.1** — Integración extendida con helpers de AUR (`yay`, `paru`, `auto`)
- [x] **v1.2** — Banderas CLI globales (`--dry-run`, `--verbose`, `--backend=<name>`)
- [x] **v2.0** — Mapeo inteligente de nombres de paquetes entre distribuciones (Local database + Repology API con caché local)
- [x] **v3.0** — Proveedores universales (`flatpak`, `snap`, `pip`, `cargo`, `npm`), ejecuciones en contenedores y SSH (`--target`), y sistema de hooks de plugins
- [ ] **v4.0** — Especificación y diseño de arquitectura avanzada de próxima generación

---

## 🔮 Propuesta y Diseño Arquitectónico de `glue v4.0`

`glue v4.0` elevará la herramienta al nivel de orquestación declarativa y gestión predictiva de entornos:

1. **Sincronización Declarativa de Manifiestos de Sistema (`glue export` / `glue sync`)**
   - Exportación de la lista completa de paquetes instalados en un archivo declarativo unificado `glue.lock`.
   - Replicación exacta del estado del sistema en cualquier otra distribución mediante `glue sync glue.lock`.

2. **Integración con Instantáneas y Snapshots del Sistema (Btrfs / Snapper / Timeshift)**
   - Creación automática de instantáneas de punto de restauración antes de cualquier operación destructiva o actualización masiva.
   - Subcomando `glue rollback` para revertir al estado anterior inmediato en caso de conflicto.

3. **Asistente Semántico y Búsqueda por Lenguaje Natural**
   - Búsqueda contextual de utilidades por función en lugar de nombre exacto (p. ej., `glue search "herramienta para editar archivos PDF"`).

4. **Panel Web y Dashboard de Monitoreo Ligero (`glue webui`)**
   - Interfaz web minimalista opcional embebida para auditar el estado de paquetes, vulnerabilidades reportadas y actualizaciones pendientes en flota de servidores.

---

## 📄 Licencia

[GNU GPL v3](LICENSE)
