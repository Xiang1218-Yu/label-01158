#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="${PROJECT_ROOT}/frontend-gui"
BUILD_DIR="${SOURCE_DIR}/build"
PACKAGE_DIR="${PROJECT_ROOT}/dist"
APP_NAME="campus_nav_gui"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }

detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "${ID}"
    elif command -v lsb_release &>/dev/null; then
        lsb_release -is | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

check_command() {
    command -v "$1" &>/dev/null
}

install_deps_macos() {
    info "检测 macOS 依赖..."

    if ! check_command brew; then
        error "未找到 Homebrew，请先安装: https://brew.sh"
        exit 1
    fi

    info "通过 Homebrew 安装依赖..."
    brew install cmake qt@6
    success "macOS 依赖安装完成"
}

install_deps_linux() {
    info "检测 Linux 依赖..."
    local distro
    distro="$(detect_linux_distro)"

    case "${distro}" in
        ubuntu|debian|linuxmint|pop)
            info "检测到 Debian 系发行版 (${distro})，使用 apt 安装依赖..."
            sudo apt-get update
            sudo apt-get install -y cmake qt6-base-dev libgl1-mesa-dev build-essential
            ;;
        fedora)
            info "检测到 Fedora，使用 dnf 安装依赖..."
            sudo dnf install -y cmake qt6-qtbase-devel mesa-libGL-devel gcc-c++ make
            ;;
        centos|rhel|rocky|alma)
            info "检测到 RHEL 系发行版 (${distro})，使用 dnf 安装依赖..."
            sudo dnf install -y cmake qt6-qtbase-devel mesa-libGL-devel gcc-c++ make
            ;;
        arch|manjaro|endeavouros)
            info "检测到 Arch 系发行版 (${distro})，使用 pacman 安装依赖..."
            sudo pacman -Sy --noconfirm cmake qt6-base mesa gcc make
            ;;
        opensuse*|sles)
            info "检测到 openSUSE，使用 zypper 安装依赖..."
            sudo zypper install -y cmake qt6-base-devel Mesa-libGL-devel gcc-c++ make
            ;;
        *)
            warn "不支持的发行版: ${distro}"
            warn "请手动安装: cmake, qt6-base-dev, libgl1-mesa-dev, gcc/g++, make"
            return 1
            ;;
    esac
    success "Linux 依赖安装完成"
}

cmd_install() {
    local os
    os="$(detect_os)"

    case "${os}" in
        macos) install_deps_macos ;;
        linux) install_deps_linux ;;
        *)     error "不支持的操作系统"; exit 1 ;;
    esac
}

cmd_configure() {
    info "配置 CMake..."

    if [ ! -d "${SOURCE_DIR}" ]; then
        error "源码目录不存在: ${SOURCE_DIR}"
        exit 1
    fi

    mkdir -p "${BUILD_DIR}"

    local cmake_args=(-B "${BUILD_DIR}" -S "${SOURCE_DIR}")

    local os
    os="$(detect_os)"
    if [ "${os}" = "macos" ]; then
        local qt_prefix
        qt_prefix="$(brew --prefix qt@6 2>/dev/null || echo "")"
        if [ -n "${qt_prefix}" ]; then
            cmake_args+=(-DCMAKE_PREFIX_PATH="${qt_prefix}")
        fi
    fi

    cmake "${cmake_args[@]}"
    success "CMake 配置完成"
}

cmd_build() {
    info "编译项目..."
    if [ ! -f "${BUILD_DIR}/CMakeCache.txt" ]; then
        cmd_configure
    fi

    local cores
    cores="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)"

    cmake --build "${BUILD_DIR}" --parallel "${cores}"
    success "编译完成: ${BUILD_DIR}/${APP_NAME}"
}

cmd_clean() {
    info "清理构建目录..."
    rm -rf "${BUILD_DIR}"
    success "清理完成"
}

cmd_package() {
    info "打包应用..."
    cmd_build

    rm -rf "${PACKAGE_DIR}"
    mkdir -p "${PACKAGE_DIR}"

    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            info "创建 macOS 应用包..."
            local app_bundle="${PACKAGE_DIR}/${APP_NAME}.app"
            mkdir -p "${app_bundle}/Contents/MacOS"
            mkdir -p "${app_bundle}/Contents/Resources"
            cp "${BUILD_DIR}/${APP_NAME}" "${app_bundle}/Contents/MacOS/"

            cat > "${app_bundle}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.aust.${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>Campus Navigator</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
EOF

            info "部署 Qt 依赖到应用包..."
            if command -v macdeployqt &>/dev/null; then
                macdeployqt "${app_bundle}"
            else
                local qt_prefix
                qt_prefix="$(brew --prefix qt@6 2>/dev/null || echo "")"
                if [ -n "${qt_prefix}" ] && [ -f "${qt_prefix}/bin/macdeployqt" ]; then
                    "${qt_prefix}/bin/macdeployqt" "${app_bundle}"
                else
                    warn "未找到 macdeployqt，跳过 Qt 依赖部署"
                    warn "在其他 Mac 上运行可能需要安装 Qt6"
                fi
            fi

            success "macOS 应用包: ${app_bundle}"
            ;;
        linux)
            info "创建 Linux 打包..."
            local pkg_dir="${PACKAGE_DIR}/${APP_NAME}"
            mkdir -p "${pkg_dir}/bin"
            mkdir -p "${pkg_dir}/lib"

            cp "${BUILD_DIR}/${APP_NAME}" "${pkg_dir}/bin/"

            if command -v linuxdeployqt &>/dev/null; then
                linuxdeployqt "${pkg_dir}/bin/${APP_NAME}" -appimage
            else
                warn "未找到 linuxdeployqt，打包为普通目录结构"
                warn "运行时需要系统已安装 Qt6 运行时库"
            fi

            local tar_name="${APP_NAME}-linux-$(date +%Y%m%d).tar.gz"
            tar -czf "${PACKAGE_DIR}/${tar_name}" -C "${PACKAGE_DIR}" "${APP_NAME}"
            success "Linux 打包: ${PACKAGE_DIR}/${tar_name}"
            ;;
        *)
            error "不支持的操作系统"
            exit 1
            ;;
    esac
}

cmd_run() {
    cmd_build
    info "启动程序..."
    local os
    os="$(detect_os)"
    if [ "${os}" = "macos" ]; then
        local qt_prefix
        qt_prefix="$(brew --prefix qt@6 2>/dev/null || echo "")"
        if [ -n "${qt_prefix}" ]; then
            DYLD_FRAMEWORK_PATH="${qt_prefix}/lib/Frameworks:${DYLD_FRAMEWORK_PATH:-}" \
                "${BUILD_DIR}/${APP_NAME}"
        else
            "${BUILD_DIR}/${APP_NAME}"
        fi
    else
        "${BUILD_DIR}/${APP_NAME}"
    fi
}

cmd_docker() {
    info "使用 Docker 构建..."
    if ! check_command docker; then
        error "未找到 Docker，请先安装"
        exit 1
    fi
    docker-compose -f "${PROJECT_ROOT}/docker-compose.yml" up --build "$@"
}

show_help() {
    cat <<EOF
${APP_NAME} 自动化构建脚本

用法: $(basename "$0") <命令> [选项]

命令:
  install    自动检测平台并安装依赖 (cmake, qt6 等)
  configure  配置 CMake 构建
  build      编译项目 (自动配置，如未配置)
  clean      清理构建目录
  package    编译并打包为可分发格式
  run        编译并运行
  docker     使用 Docker 构建运行
  help       显示此帮助信息

示例:
  ./scripts/build.sh install     # 首次使用：安装所有依赖
  ./scripts/build.sh build       # 编译项目
  ./scripts/build.sh package     # 编译并打包
  ./scripts/build.sh run         # 编译并运行
  ./scripts/build.sh docker      # Docker 方式运行

支持平台:
  - macOS (通过 Homebrew)
  - Ubuntu / Debian
  - Fedora / RHEL / CentOS
  - Arch / Manjaro
  - openSUSE
EOF
}

main() {
    local cmd="${1:-help}"

    case "${cmd}" in
        install)   cmd_install ;;
        configure) cmd_configure ;;
        build)     cmd_build ;;
        clean)     cmd_clean ;;
        package)   cmd_package ;;
        run)       cmd_run ;;
        docker)    shift; cmd_docker "$@" ;;
        help|-h|--help) show_help ;;
        *) error "未知命令: ${cmd}"; echo; show_help; exit 1 ;;
    esac
}

main "$@"
