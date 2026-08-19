#!/usr/bin/env bash
# tests/test_runner.sh - Test suite runner for glue

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TESTS_PASSED=0
TESTS_FAILED=0

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo "  [PASS] $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "  [FAIL] $test_name"
        echo "    Expected: '$expected'"
        echo "    Actual:   '$actual'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "Running glue tests..."
echo "=============================="

# Test 1: Config loading & getting
echo "Test Group 1: Config Management"
export GLUE_CONFIG_FILE="/tmp/test_glue_config_1"
rm -f "$GLUE_CONFIG_FILE"

source "$ROOT_DIR/lib/config.sh"
glue_config_set "dialect" "pacman" >/dev/null
glue_config_set "dry_run" "true" >/dev/null

val_dialect=$(glue_config_get "dialect")
val_dry_run=$(glue_config_get "dry_run")

assert_equals "pacman" "$val_dialect" "Config set and get dialect"
assert_equals "true" "$val_dry_run" "Config set and get dry_run"

rm -f "$GLUE_CONFIG_FILE"


# Test 2: Detection
echo "Test Group 2: System Detection"
source "$ROOT_DIR/lib/detect.sh"

# Mock Arch os-release
arch_release="/tmp/os_release_arch"
echo 'ID=arch' > "$arch_release"
echo 'ID_LIKE=arch' >> "$arch_release"
GLUE_OS_RELEASE="$arch_release"
detected=$(glue_detect_system)
assert_equals "pacman" "$detected" "Detect Arch Linux -> pacman"
rm -f "$arch_release"

# Mock CachyOS os-release (which lacks ID_LIKE=arch)
cachy_release="/tmp/os_release_cachy"
echo 'ID=cachyos' > "$cachy_release"
GLUE_OS_RELEASE="$cachy_release"
detected=$(glue_detect_system)
assert_equals "pacman" "$detected" "Detect CachyOS -> pacman"
rm -f "$cachy_release"

# Mock Ubuntu os-release
ubuntu_release="/tmp/os_release_ubuntu"
echo 'ID=ubuntu' > "$ubuntu_release"
echo 'ID_LIKE=debian' >> "$ubuntu_release"
GLUE_OS_RELEASE="$ubuntu_release"
detected=$(glue_detect_system)
assert_equals "apt" "$detected" "Detect Ubuntu -> apt"
rm -f "$ubuntu_release"

# Mock Fedora os-release
fedora_release="/tmp/os_release_fedora"
echo 'ID=fedora' > "$fedora_release"
GLUE_OS_RELEASE="$fedora_release"
detected=$(glue_detect_system)
assert_equals "dnf" "$detected" "Detect Fedora -> dnf"
rm -f "$fedora_release"

# Mock openSUSE Tumbleweed os-release
suse_release="/tmp/os_release_suse"
echo 'ID=opensuse-tumbleweed' > "$suse_release"
GLUE_OS_RELEASE="$suse_release"
detected=$(glue_detect_system)
assert_equals "zypper" "$detected" "Detect openSUSE -> zypper"
rm -f "$suse_release"

# Mock Alpine os-release
alpine_release="/tmp/os_release_alpine"
echo 'ID=alpine' > "$alpine_release"
GLUE_OS_RELEASE="$alpine_release"
detected=$(glue_detect_system)
assert_equals "apk" "$detected" "Detect Alpine -> apk"
rm -f "$alpine_release"

# Mock Void os-release
void_release="/tmp/os_release_void"
echo 'ID=void' > "$void_release"
GLUE_OS_RELEASE="$void_release"
detected=$(glue_detect_system)
assert_equals "xbps" "$detected" "Detect Void Linux -> xbps"
rm -f "$void_release"

# Mock Gentoo os-release
gentoo_release="/tmp/os_release_gentoo"
echo 'ID=gentoo' > "$gentoo_release"
GLUE_OS_RELEASE="$gentoo_release"
detected=$(glue_detect_system)
assert_equals "emerge" "$detected" "Detect Gentoo Linux -> emerge"
rm -f "$gentoo_release"

# Mock Solus os-release
solus_release="/tmp/os_release_solus"
echo 'ID=solus' > "$solus_release"
GLUE_OS_RELEASE="$solus_release"
detected=$(glue_detect_system)
assert_equals "eopkg" "$detected" "Detect Solus -> eopkg"
rm -f "$solus_release"

# Mock NixOS os-release
nix_release="/tmp/os_release_nix"
echo 'ID=nixos' > "$nix_release"
GLUE_OS_RELEASE="$nix_release"
detected=$(glue_detect_system)
assert_equals "nix" "$detected" "Detect NixOS -> nix"
rm -f "$nix_release"


# Test 3: Backend Translation (Dry Run mode)
echo "Test Group 3: Backend Translation & Dispatch (Dry Run)"
export GLUE_CONFIG_FILE="/tmp/test_glue_config_3"
rm -f "$GLUE_CONFIG_FILE"

export GLUE_DRY_RUN=true
export GLUE_VERBOSE=false
export GLUE_BACKEND=pacman
export GLUE_USE_AUR_HELPER=none

source "$ROOT_DIR/lib/config.sh"
source "$ROOT_DIR/lib/detect.sh"
source "$ROOT_DIR/lib/pkgmap.sh"
source "$ROOT_DIR/lib/backends/apt.sh"
source "$ROOT_DIR/lib/backends/pacman.sh"
source "$ROOT_DIR/lib/backends/dnf.sh"
source "$ROOT_DIR/lib/backends/zypper.sh"
source "$ROOT_DIR/lib/backends/apk.sh"
source "$ROOT_DIR/lib/backends/xbps.sh"
source "$ROOT_DIR/lib/core.sh"

out_install=$(glue_dispatch "install" "neovim")
assert_equals "sudo pacman -S neovim" "$out_install" "Pacman install translation"

out_remove=$(glue_dispatch "remove" "neovim")
assert_equals "sudo pacman -R neovim" "$out_remove" "Pacman remove translation"

out_update=$(glue_dispatch "update")
assert_equals "sudo pacman -Syu" "$out_update" "Pacman safe update translation (-Syu)"

out_search=$(glue_dispatch "search" "ripgrep")
assert_equals "pacman -Ss ripgrep" "$out_search" "Pacman search translation (no sudo)"

GLUE_BACKEND=apt
out_apt_install=$(glue_dispatch "install" "neovim")
assert_equals "sudo apt install neovim" "$out_apt_install" "APT install translation"

out_apt_update=$(glue_dispatch "update")
assert_equals "sudo apt update" "$out_apt_update" "APT update translation"

GLUE_BACKEND=dnf
out_dnf_install=$(glue_dispatch "install" "neovim")
assert_equals "sudo dnf install neovim" "$out_dnf_install" "DNF install translation"

GLUE_BACKEND=zypper
out_zypper_install=$(glue_dispatch "install" "neovim")
assert_equals "sudo zypper install neovim" "$out_zypper_install" "Zypper install translation"

GLUE_BACKEND=apk
out_apk_install=$(glue_dispatch "install" "neovim")
assert_equals "sudo apk add neovim" "$out_apk_install" "APK install translation"

GLUE_BACKEND=xbps
out_xbps_install=$(glue_dispatch "install" "neovim")
assert_equals "sudo xbps-install -S neovim" "$out_xbps_install" "XBPS install translation"

rm -f "$GLUE_CONFIG_FILE"


# Test 4: Global CLI Flags & Overrides
echo "Test Group 4: Global CLI Flags & Overrides"
export GLUE_DRY_RUN=false
export GLUE_VERBOSE=false
export GLUE_BACKEND=apt

out_flag_dry=$(glue_dispatch --dry-run install neovim)
assert_equals "sudo apt install neovim" "$out_flag_dry" "Global --dry-run flag override"

out_flag_backend=$(glue_dispatch --dry-run --backend=apk install neovim)
assert_equals "sudo apk add neovim" "$out_flag_backend" "Global --backend=apk flag override"


# Test 5: Package Name Mapping & Repology Cache
echo "Test Group 5: Package Name Mapping & Repology Cache"
map_apt_pip=$(glue_resolve_local_map apt pip)
assert_equals "python3-pip" "$map_apt_pip" "Local map 'pip' -> APT python3-pip"

map_pacman_pip=$(glue_resolve_local_map pacman pip)
assert_equals "python-pip" "$map_pacman_pip" "Local map 'pip' -> Pacman python-pip"

map_dnf_build=$(glue_resolve_local_map dnf build-essential)
assert_equals "gcc-c++" "$map_dnf_build" "Local map 'build-essential' -> DNF gcc-c++"

map_apt_fd=$(glue_resolve_local_map apt fd)
assert_equals "fd-find" "$map_apt_fd" "Local map 'fd' -> APT fd-find"

mkdir -p /tmp/glue_cache_test
export GLUE_CACHE_DIR="/tmp/glue_cache_test"
echo '[{"repo":"arch","srcname":"fd"},{"repo":"debian_11","srcname":"fd-find"}]' > /tmp/glue_cache_test/fd.json

repo_match=$(glue_repology_lookup apt fd)
assert_equals "fd-find" "$repo_match" "Repology JSON parser correctly extracts Debian srcname"

rm -rf /tmp/glue_cache_test


# Test 6: Providers, Targets & Plugins
echo "Test Group 6: Universal Providers, Targets & Plugins"
export GLUE_DRY_RUN=true
export GLUE_VERBOSE=false

out_flatpak=$(glue_dispatch --provider=flatpak install org.gimp.GIMP)
assert_equals "flatpak install org.gimp.GIMP" "$out_flatpak" "Provider flatpak install translation"

out_snap=$(glue_dispatch --provider=snap install code)
assert_equals "sudo snap install code" "$out_snap" "Provider snap install translation"

out_cargo=$(glue_dispatch --provider=cargo install ripgrep)
assert_equals "cargo install ripgrep" "$out_cargo" "Provider cargo install translation"

out_pip=$(glue_dispatch --provider=pip install requests)
assert_equals "pip install requests" "$out_pip" "Provider pip install requests"

out_npm=$(glue_dispatch --provider=npm install typescript)
assert_equals "npm install -g typescript" "$out_npm" "Provider npm install typescript"

out_target_docker=$(glue_dispatch --dry-run --target=docker:my_ubuntu install neovim)
assert_equals "docker exec -it my_ubuntu sudo apt install neovim" "$out_target_docker" "Target docker exec wrapper"

out_target_ssh=$(glue_dispatch --dry-run --target=ssh://remote-host install neovim)
assert_equals "ssh remote-host sudo apt install neovim" "$out_target_ssh" "Target ssh wrapper"

mkdir -p /tmp/glue_plugins_test
cat << 'EOF' > /tmp/glue_plugins_test/hook.sh
glue_plugin_pre_install() {
    export HOOK_TRIGGERED="pre_install_ok"
}
EOF
export XDG_CONFIG_HOME="/tmp/glue_plugins_test_config"
mkdir -p "$XDG_CONFIG_HOME/glue/plugins"
cp /tmp/glue_plugins_test/hook.sh "$XDG_CONFIG_HOME/glue/plugins/"

glue_dispatch --dry-run install neovim >/dev/null
assert_equals "pre_install_ok" "${HOOK_TRIGGERED:-}" "Plugin pre-install hook execution"

rm -rf /tmp/glue_plugins_test /tmp/glue_plugins_test_config


# Test 7: Advanced Subcommands (v4.0 - v1.0.1 LTS)
echo "Test Group 7: Advanced Subcommands (Sync, AI, WebUI, Cluster, Audit, Repair, Trace, Wasm, Daemon, Build, Verify, Graph, Sandbox, Predict, MicroVM, Telemetry, Version)"
export GLUE_DIALECT=apt
export GLUE_ACTIVE_BACKEND=apt
source "$ROOT_DIR/glue.sh"

manifest_file="/tmp/test_glue.lock"
rm -f "$manifest_file"
glue export "$manifest_file" >/dev/null
assert_equals "true" "$([[ -f "$manifest_file" ]] && echo "true" || echo "false")" "glue export generates manifest file"

ai_res=$(glue_ai_search "editor de texto")
assert_equals "neovim vim nano" "$ai_res" "glue_ai_search maps natural language query"

webui_out=$(GLUE_DRY_RUN=true glue webui 9090)
assert_equals "Starting Glue Web UI Dashboard (v1.0.1 LTS) on http://localhost:9090...
Active Backend: apt
Active Dialect: apt
WebUI dry-run server ready." "$webui_out" "glue webui dry-run launch"

cluster_out=$(GLUE_DRY_RUN=true glue cluster node-1)
assert_equals "[glue-cluster] Initiating cluster package synchronization...
[glue-cluster] Node target: node-1
glue export /tmp/cluster_sync.lock" "$cluster_out" "glue cluster execution"

audit_out=$(GLUE_DRY_RUN=true glue audit)
assert_equals "[glue-audit] Auditing installed packages for security advisories...
[glue-audit] Scanning packages on backend 'apt' against OSV / CVE advisories...
glue audit scan --backend=apt" "$audit_out" "glue audit execution"

repair_out=$(GLUE_DRY_RUN=true glue repair)
assert_equals "[glue-repair] Diagnosing package manager state...
[glue-repair] Attempting auto-repair on backend 'apt'...
sudo dpkg --configure -a" "$repair_out" "glue repair execution"

trace_out=$(GLUE_DRY_RUN=true glue trace apt install neovim)
assert_equals "[glue-trace] Attaching eBPF call tracer...
glue-trace-ebpf -- apt install neovim" "$trace_out" "glue trace dry-run execution"

wasm_out=$(GLUE_DRY_RUN=true glue plugin list)
assert_equals "[glue-wasm] Wasm plugin engine interface (list)...
wasm-runtime exec --plugin list" "$wasm_out" "glue plugin dry-run execution"

daemon_out=$(GLUE_DRY_RUN=true glue daemon status)
assert_equals "[glue-daemon] Autonomous maintenance daemon service (status)...
glue-daemon --service status" "$daemon_out" "glue daemon dry-run execution"

build_out=$(GLUE_DRY_RUN=true glue build neovim-git)
assert_equals "[glue-build] Distributing compilation task for 'neovim-git' across cluster nodes...
p2p-build-cluster dispatch --pkg=neovim-git" "$build_out" "glue build dry-run execution"

verify_out=$(GLUE_DRY_RUN=true glue verify "$manifest_file")
assert_equals "[glue-verify] Verifying cryptographic signatures for manifest '$manifest_file'...
gpg --verify $manifest_file.sig $manifest_file" "$verify_out" "glue verify dry-run execution"

graph_out=$(GLUE_DRY_RUN=true glue graph neovim)
assert_equals "[glue-graph] Resolving dependency graph tree for 'neovim' across repos...
glue-dep-graph --resolve neovim" "$graph_out" "glue graph dry-run execution"

sandbox_out=$(GLUE_DRY_RUN=true glue sandbox apt install neovim)
assert_equals "[glue-sandbox] Initializing unshare/chroot ephemeral sandbox environment...
unshare --user --map-root-user -- apt install neovim" "$sandbox_out" "glue sandbox dry-run execution"

predict_out=$(GLUE_DRY_RUN=true glue predict python3)
assert_equals "[glue-predict] Running neural network heuristic conflict prediction for: python3...
glue-nn-predict --check python3" "$predict_out" "glue predict dry-run execution"

microvm_out=$(GLUE_DRY_RUN=true glue microvm apt install neovim)
assert_equals "[glue-microvm] Spawning Firecracker microVM isolated test environment...
firecracker-spawn --exec apt install neovim" "$microvm_out" "glue microvm dry-run execution"

telemetry_out=$(glue telemetry status)
assert_equals "[glue-telemetry] Fleet health telemetry status (v1.0.1 LTS)...
[glue-telemetry] Status: Local metrics active (0 errors reported)." "$telemetry_out" "glue telemetry status execution"

version_out=$(glue version)
assert_equals "glue v1.0.1-lts" "$version_out" "glue version output"

rm -f "$manifest_file"


# Test 8: Neutral CLI & Dialects
echo "Test Group 8: Neutral CLI & Dialects"
export GLUE_CONFIG_FILE="/tmp/test_glue_config_8"
rm -f "$GLUE_CONFIG_FILE"

export GLUE_DRY_RUN=true
export GLUE_VERBOSE=false
export GLUE_DIALECT=apt
export GLUE_BACKEND=pacman
export GLUE_USE_AUR_HELPER=none

source "$ROOT_DIR/glue.sh"

out_apt_cmd=$(apt install neovim)
assert_equals "sudo pacman -S neovim" "$out_apt_cmd" "APT dialect 'apt install neovim' on pacman backend"

out_apt_up=$(apt update)
assert_equals "sudo pacman -Syu" "$out_apt_up" "APT dialect 'apt update' on pacman backend"

out_glue_cmd=$(glue install neovim)
assert_equals "sudo pacman -S neovim" "$out_glue_cmd" "Neutral CLI 'glue install neovim' on pacman backend"

rm -f "$GLUE_CONFIG_FILE"

echo "=============================="
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
fi
