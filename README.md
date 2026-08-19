# glue

> Un único lenguaje de comandos para gestionar paquetes, sin importar en qué distribución de Linux estés.

![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-GNU_GPL_v3-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

**Estado:** ✅ v4.0 completado — Manifiesto declarativo (`glue export`/`sync`), integración con instantáneas y rollback (`glue rollback`), búsqueda semántica e IA (`glue search --ai`), y servidor WebUI dashboard (`glue webui`).

---

## 🧩 ¿Qué es `glue`?

`glue` es una capa de abstracción, escrita en bash puro, que se sitúa entre tú y el gestor de paquetes nativo de cada distribución Linux. Su objetivo es simple: que nunca más tengas que recordar qué comando usa cada sistema ni cómo se llama exactamente un paquete en cada repositorio.

El nombre no es casual: `glue` (pegamento) es literalmente lo que hace — pega tu forma de trabajar habitual sobre cualquier sistema, en lugar de obligarte a adaptarte tú a cada uno.

## ⚙️ Características Destacadas v4.0

1. **Gestión Declarativa de Manifiestos (`glue export` / `glue sync`)**
   - Exporta el inventario completo del sistema a un manifiesto reproducible `glue.lock`.
   - Replica la configuración de paquetes en cualquier distribución con `glue sync`.

2. **Integración de Instantáneas y Restauración (`glue rollback`)**
   - Inspección y restauración automática con Snapper / Timeshift o etiquetas de manifiesto de respaldo.

3. **Búsqueda Semántica con IA (`glue search --ai`)**
   - Mapeo inteligente por lenguaje natural (p. ej. "editor de texto", "compilador c++", "api client").

4. **Dashboard WebUI Integrado (`glue webui`)**
   - Servidor web ligero embebido para consultar el estado del motor y paquetes.

## 🛠️ Ejemplos de Uso v4.0

```bash
# Exportar el manifiesto del sistema actual:
glue export mis_paquetes.lock

# Sincronizar un nuevo servidor desde el manifiesto:
glue sync mis_paquetes.lock

# Búsqueda semántica inteligente con IA:
glue search --ai "editor de texto"

# Ver snapshots del sistema / crear punto de respaldo:
glue rollback

# Lanzar dashboard WebUI:
glue webui 8080
```

## 🗺️ Roadmap de versiones

- [x] **v1.0** — Detección de SO + dialectos/backends para `apt`, `pacman`, `dnf`, `zypper`, `apk`, `xbps`
- [x] **v1.1** — Integración extendida con helpers de AUR (`yay`, `paru`, `auto`)
- [x] **v1.2** — Banderas CLI globales (`--dry-run`, `--verbose`, `--backend=<name>`)
- [x] **v2.0** — Mapeo inteligente de nombres de paquetes entre distribuciones (Local database + Repology API con caché local)
- [x] **v3.0** — Proveedores universales (`flatpak`, `snap`, `pip`, `cargo`, `npm`), ejecuciones en contenedores y SSH (`--target`), y sistema de hooks de plugins
- [x] **v4.0** — Manifiesto declarativo (`export`/`sync`), snapshot rollback, búsqueda IA semántica y servidor WebUI dashboard
- [ ] **v5.0** — Propuesta de Arquitectura Futura (Diseño detallado a continuación)

---

## 🔮 Propuesta y Diseño Arquitectónico de `glue v5.0`

`glue v5.0` evolucionará la herramienta hacia una plataforma distribuida, autónoma y resiliente para flotas heterogéneas de sistemas Linux:

### 📐 Principales Pilares de v5.0

1. **Orquestación en Flotas y Clústeres P2P (`glue cluster`)**
   - Sincronización descentralizada del estado de paquetes entre múltiples nodos de una red o clúster local mediante descubrimiento mDNS/Zeroconf.
   - Distribución P2P de caché de paquetes binarios para acelerar despliegues en servidores sin salida directa a internet.

2. **Verificación de Seguridad Automática y Parcheo de Vulnerabilidades (`glue audit`)**
   - Integración nativa con bases de datos de vulnerabilidades CVE (NVD, OSV.dev).
   - Auditoría automática antes de instalar o actualizar paquetes e informe de parches críticos de seguridad.

3. **Autocuración del Sistema y Reparación Predictiva (`glue repair`)**
   - Detección de dependencias rotas, repositorios inalcanzables o paquetes corruptos y reparación automatizada entre gestores.

4. **Soporte Nativo de Sistemas Inmutables y Atómicos (NixOS, Fedora Silverblue, microOS)**
   - Transpilación declarativa hacia configuraciones inmutables (`configuration.nix`, `rpm-ostree`) manteniendo la sintaxis interactiva del dialecto preferido.

---

## 📄 Licencia

[GNU GPL v3](LICENSE)
