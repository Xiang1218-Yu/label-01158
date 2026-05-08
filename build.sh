#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/frontend-gui" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/dist"

OS_NAME=$(uname -s)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

detect_os() {
    case "$OS_NAME" in
        Darwin)
            log_info "检测到 macOS 系统"
            PLATFORM="macos"
            ;;
        Linux)
            log_info "检测到 Linux 系统"
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian)
                        PLATFORM="debian"
                        log_info "基于 Debian 的发行版: $PRETTY_NAME"
                        ;;
                    *)
                        PLATFORM="linux"
                        log_warning "未完全支持的 Linux 发行版: $PRETTY_NAME"
                        ;;
                esac
            else
                PLATFORM="linux"
                log_warning "无法确定 Linux 发行版"
            fi
            ;;
        *)
            log_error "不支持的操作系统: $OS_NAME"
            exit 1
            ;;
    esac
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

check_dependencies() {
    log_info "检查依赖..."
    
    INSTALL_DEPS=false
    
    if ! check_command cmake; then
        log_warning "CMake 未安装"
        INSTALL_DEPS=true
    else
        log_success "CMake 已安装: $(cmake --version | head -n1)"
    fi
    
    if ! check_command qmake6; then
        if ! check_command qmake; then
            if ! check_command qmake-qt6; then
                log_warning "Qt6 未安装"
                INSTALL_DEPS=true
            else
                log_success "Qt6 已安装"
            fi
        else
            QT_VERSION=$(qmake --version 2>/dev/null | grep "Qt version" || echo "")
            if [[ "$QT_VERSION" == *"Qt version 6"* ]]; then
                log_success "Qt6 已安装: $QT_VERSION"
            else
                log_warning "当前 Qt 版本可能不是 Qt6"
                INSTALL_DEPS=true
            fi
        fi
    else
        log_success "Qt6 已安装"
    fi
    
    if [ "$INSTALL_DEPS" = true ]; then
        read -p "是否自动安装缺失的依赖? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_dependencies
        else
            log_error "需要先安装依赖才能继续构建"
            exit 1
        fi
    fi
}

install_dependencies() {
    log_info "开始安装依赖..."
    
    case "$PLATFORM" in
        macos)
            if check_command brew; then
                log_info "使用 Homebrew 安装依赖..."
                brew install cmake qt@6
                log_info "配置 Qt6 环境变量..."
                echo 'export PATH="/usr/local/opt/qt@6/bin:$PATH"' >> ~/.bash_profile
                echo 'export PATH="/opt/homebrew/opt/qt@6/bin:$PATH"' >> ~/.bash_profile
                echo 'export CMAKE_PREFIX_PATH="/usr/local/opt/qt@6:$CMAKE_PREFIX_PATH"' >> ~/.bash_profile
                echo 'export CMAKE_PREFIX_PATH="/opt/homebrew/opt/qt@6:$CMAKE_PREFIX_PATH"' >> ~/.bash_profile
            else
                log_error "未检测到 Homebrew，请先安装: https://brew.sh/"
                exit 1
            fi
            ;;
        debian)
            log_info "使用 apt 安装依赖..."
            sudo apt-get update
            sudo apt-get install -y build-essential cmake qt6-base-dev libgl1-mesa-dev
            ;;
        *)
            log_error "请手动安装 CMake 和 Qt6"
            exit 1
            ;;
    esac
    
    log_success "依赖安装完成"
}

clean_build() {
    if [ -d "$BUILD_DIR" ]; then
        log_info "清理旧的构建目录..."
        rm -rf "$BUILD_DIR"
        log_success "构建目录已清理"
    fi
}

configure_project() {
    log_info "配置 CMake 项目..."
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    cmake -DCMAKE_BUILD_TYPE=Release ..
    
    log_success "CMake 配置完成"
}

build_project() {
    log_info "开始编译项目..."
    cd "$BUILD_DIR"
    
    if [ "$PLATFORM" = "macos" ]; then
        cmake --build . -- -j$(sysctl -n hw.ncpu)
    else
        cmake --build . -- -j$(nproc)
    fi
    
    log_success "项目编译完成"
}

package_project() {
    log_info "开始打包..."
    
    mkdir -p "$OUTPUT_DIR"
    
    EXECUTABLE="$BUILD_DIR/campus_nav_gui"
    
    if [ ! -f "$EXECUTABLE" ]; then
        log_error "可执行文件未找到: $EXECUTABLE"
        exit 1
    fi
    
    case "$PLATFORM" in
        macos)
            APP_DIR="$OUTPUT_DIR/campus_nav_gui.app"
            if [ -d "$APP_DIR" ]; then
                rm -rf "$APP_DIR"
            fi
            mkdir -p "$APP_DIR/Contents/MacOS"
            mkdir -p "$APP_DIR/Contents/Resources"
            cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/"
            
            cat > "$APP_DIR/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>campus_nav_gui</string>
    <key>CFBundleIdentifier</key>
    <string>com.campusnav.gui</string>
    <key>CFBundleName</key>
    <string>Campus Nav GUI</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF
            
            if check_command macdeployqt; then
                log_info "使用 macdeployqt 部署 Qt 依赖..."
                macdeployqt "$APP_DIR" -dmg -verbose=1
            else
                log_warning "macdeployqt 未找到，未部署 Qt 依赖"
            fi
            ;;
        *)
            LINUX_DIR="$OUTPUT_DIR/campus_nav_gui-linux"
            mkdir -p "$LINUX_DIR"
            cp "$EXECUTABLE" "$LINUX_DIR/"
            
            cat > "$LINUX_DIR/run.sh" << 'EOF'
#!/usr/bin/env bash
cd "$(dirname "$0")"
./campus_nav_gui
EOF
            chmod +x "$LINUX_DIR/run.sh"
            
            log_success "Linux 打包完成: $LINUX_DIR"
            ;;
    esac
    
    log_success "打包完成，输出目录: $OUTPUT_DIR"
}

show_help() {
    cat << 'EOF'
自动化构建脚本

使用方法:
  ./build.sh [选项]

选项:
  --help, -h          显示帮助信息
  --clean             清理构建目录并重新构建
  --deps              仅安装依赖
  --build             仅编译项目
  --package           仅打包项目
  --all               完整流程: 检查依赖 -> 编译 -> 打包 (默认)
  --docker            使用 Docker 构建

示例:
  ./build.sh                    # 完整构建流程
  ./build.sh --clean            # 清理并重新构建
  ./build.sh --docker           # 使用 Docker 构建
EOF
}

build_with_docker() {
    log_info "使用 Docker 构建..."
    
    if ! check_command docker; then
        log_error "Docker 未安装"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    
    log_info "构建 Docker 镜像..."
    docker-compose build
    
    log_success "Docker 镜像构建完成"
    
    mkdir -p "$OUTPUT_DIR"
    
    log_info "从 Docker 容器中提取可执行文件..."
    docker create --name temp-container campus-nav-gui:latest
    docker cp temp-container:/app/campus_nav_gui "$OUTPUT_DIR/"
    docker rm temp-container
    
    log_success "可执行文件已保存到: $OUTPUT_DIR/campus_nav_gui"
}

main() {
    ACTION="all"
    CLEAN=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --clean)
                CLEAN=true
                shift
                ;;
            --deps)
                ACTION="deps"
                shift
                ;;
            --build)
                ACTION="build"
                shift
                ;;
            --package)
                ACTION="package"
                shift
                ;;
            --all)
                ACTION="all"
                shift
                ;;
            --docker)
                ACTION="docker"
                shift
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    detect_os
    
    if [ "$ACTION" = "docker" ]; then
        build_with_docker
        exit 0
    fi
    
    if [ "$ACTION" = "deps" ] || [ "$ACTION" = "all" ]; then
        check_dependencies
    fi
    
    if [ "$ACTION" = "build" ] || [ "$ACTION" = "all" ]; then
        if [ "$CLEAN" = true ]; then
            clean_build
        fi
        configure_project
        build_project
    fi
    
    if [ "$ACTION" = "package" ] || [ "$ACTION" = "all" ]; then
        package_project
    fi
    
    echo
    log_success "构建流程完成！"
}

main "$@"
