# 安徽理工大学校园导航系统

基于最短路径算法的校园导游程序，使用 Qt6 图形界面，为来访客人提供景点信息查询和路径规划服务。

---

## CI/CD 持续集成

本项目使用 GitHub Actions 实现全自动化的持续集成和持续部署流程。

### 工作流概览

| 工作流 | 触发条件 | 说明 |
|--------|----------|------|
| [**CI - 跨平台构建测试**](.github/workflows/ci.yml) | `push` / `pull_request` | Linux/macOS/Windows 三平台构建验证 |
| [**CI - 代码质量检查**](.github/workflows/quality-check.yml) | `push` / `pull_request` | 代码格式、安全扫描 |
| [**CI - Docker 镜像构建**](.github/workflows/docker.yml) | `push` / `pull_request` / `tag` | 自动构建并推送 Docker 镜像 |
| [**CD - 自动发布**](.github/workflows/release.yml) | `tag: v*` | 自动打包并创建 GitHub Release |

### 构建状态徽章

将以下代码添加到 README 开头，显示构建状态：

```markdown
![CI - 跨平台构建测试](https://github.com/USERNAME/REPO/actions/workflows/ci.yml/badge.svg)
![CI - 代码质量检查](https://github.com/USERNAME/REPO/actions/workflows/quality-check.yml/badge.svg)
![CI - Docker 镜像构建](https://github.com/USERNAME/REPO/actions/workflows/docker.yml/badge.svg)
```

### 发布新版本

```bash
# 1. 创建并推送标签
git tag v1.0.0
git push origin v1.0.0

# 或者使用语义化版本
git tag v1.0.1
git push origin v1.0.1
```

推送标签后，GitHub Actions 会自动：
1. 🔧 构建三个平台的可执行文件
2. 📦 自动打包（tar.gz / dmg / zip）
3. 🚢 构建并推送 Docker 镜像
4. 📝 创建 GitHub Release 并上传所有产物

### Docker 镜像

镜像会自动推送到 GitHub Container Registry：

```bash
# 拉取最新版本
docker pull ghcr.io/USERNAME/REPO/campus-nav-gui:latest

# 拉取特定版本
docker pull ghcr.io/USERNAME/REPO/campus-nav-gui:v1.0.0

# 运行
xhost +local:docker
docker run -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  ghcr.io/USERNAME/REPO/campus-nav-gui:latest
```

---

## How to Run

### 快速启动（3步）

```bash
# 步骤1: 进入项目目录，创建构建文件夹
cd frontend-gui
mkdir -p build
cd build

# 步骤2: 配置并编译
cmake ..
make

# 步骤3: 运行程序
./campus_nav_gui
```

---

### 详细说明

#### 环境要求

**macOS:**
```bash
brew install cmake qt@6
```

**Ubuntu/Debian:**
```bash
sudo apt-get install cmake qt6-base-dev libgl1-mesa-dev
```

**Windows:**
- 安装 [Qt6](https://www.qt.io/download) 和 [CMake](https://cmake.org/download/)

#### VS Code 调试运行

1. 用 VS Code 打开项目根目录
2. 按 `Cmd+Shift+B` (macOS) 或 `Ctrl+Shift+B` (Windows/Linux) 编译
3. 按 `F5` 启动调试

#### Docker 运行（Linux with X11）

```bash
# 允许 X11 连接
xhost +local:docker

# 启动容器
docker-compose up --build

# 停止
docker-compose down
```

## Services

| 组件 | 说明 |
|------|------|
| campus_nav_gui | Qt6 图形界面应用程序 |

## 测试账号

本系统无需登录，直接运行即可使用。

## 题目内容

### 问题描述
设计一个校园导游程序，为来访的客人提供多种信息查询服务，帮助他们轻松了解校园内的各个景点及路径。

### 基本要求
1. 设计安徽理工大学的校园平面图，所含景点不少于10个
2. 提供查询功能，用户可以查询图中任意景点的相关信息
3. 提供问路查询功能，使用 Dijkstra 算法查询任意两个景点之间的最短路径
4. 提供多个景点的最佳访问路线查询
5. 使用图形界面进行程序的交互展示

### 景点列表（16个）

| 代号 | 名称 | 类型 |
|------|------|------|
| BCH | 百川河 | 景观 |
| AQQ | 爱情桥 | 景观 |
| ZCTC | 至诚体育场 | 体育 |
| RACC | 仁爱操场 | 体育 |
| XYCC | 信义操场 | 体育 |
| TSG | 图书馆 | 教学 |
| YSGC | 仰山广场 | 景观 |
| CXCY | 创新创业中心 | 办公 |
| XSG | 校史馆 | 文化 |
| XZL | 行政楼 | 办公 |
| HDG | 厚德馆 | 教学 |
| TGJX | 天工教学楼 | 教学 |
| MLJX | 明理教学楼 | 教学 |
| ZSJC | 钻石剧场 | 文化 |
| GJSY | 国家重点实验室 | 科研 |
| ZQTG | 自强体育馆 | 体育 |

---

## 功能说明

### 1. 校园地图显示
- 可视化显示校园平面图
- 不同类型建筑用不同颜色区分
- 显示道路连接和距离
- 包含指北针和比例尺

### 2. 景点信息查询
- 左侧景点列表，支持搜索过滤
- 点击景点显示详细信息（名称、代号、简介）
- 地图上点击景点同步显示信息

### 3. 两点最短路径查询
- 选择起点和终点
- 使用 Dijkstra 算法计算最短路径
- 地图上高亮显示路径
- 显示路径经过的景点和总距离

### 4. 多景点最佳路线
- 勾选多个要经过的景点
- 使用贪心算法规划最佳路线
- 显示完整路线和总距离

---

## 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 语言 | C++17 | 高性能，适合算法实现 |
| GUI框架 | Qt6 | 跨平台图形界面框架 |
| 图形绘制 | QPainter | Qt 2D 绑图引擎 |
| 构建工具 | CMake | 跨平台构建系统 |
| 容器化 | Docker | 可选的容器化部署 |
| CI/CD | GitHub Actions | 自动化构建和发布 |
| 代码检查 | CodeQL | 安全漏洞扫描 |

### 核心算法

- **Dijkstra 算法**：求解两点间最短路径，时间复杂度 O((V+E)logV)
- **贪心算法**：多景点路径规划，每次选择最近的未访问景点

---

## CI/CD 工作流

```
代码提交 / Pull Request
    │
    ▼
┌─────────────────┐     ┌─────────────────┐
│  代码质量检查   │     │  跨平台构建测试 │
│  - clang-format │ ──► │  - Linux        │
│  - cmake-lint   │     │  - macOS        │
│  - CodeQL 扫描  │     │  - Windows      │
└─────────────────┘     └─────────────────┘
    │                          │
    └──────────┬───────────────┘
               ▼
        合并到 main 分支
               │
               ▼
        ┌─────────────────┐
        │ Docker 镜像构建 │
        │ - linux/amd64   │
        │ - linux/arm64   │
        └─────────────────┘
               │
               ▼
        推送标签 vX.X.X
               │
               ▼
        ┌─────────────────┐
        │  自动发布       │
        │ - 三平台打包    │
        │ - GitHub Release│
        └─────────────────┘
```

---

## 项目结构

```
├── frontend-gui/               # Qt6 图形界面
│   ├── include/               # 头文件
│   │   ├── mainwindow.h       # 主窗口
│   │   ├── mapwidget.h        # 地图绑制组件
│   │   ├── graph.h            # 图数据结构
│   │   └── campus_data.h      # 校园数据
│   ├── src/                   # 源文件
│   │   ├── main.cpp           # 程序入口
│   │   ├── mainwindow.cpp     # 主窗口实现
│   │   ├── mapwidget.cpp      # 地图绘制实现
│   │   ├── graph.cpp          # 图算法实现
│   │   └── campus_data.cpp    # 校园数据初始化
│   ├── CMakeLists.txt         # CMake 配置
│   └── Dockerfile             # Docker 配置
├── .vscode/                   # VS Code 配置
│   ├── launch.json            # 调试配置
│   └── tasks.json             # 任务配置
├── docker-compose.yml         # Docker 编排
├── .gitignore                 # Git 忽略规则
└── README.md                  # 项目说明
```

## 界面预览

程序启动后显示三栏布局：
- **左侧**：景点搜索和列表、景点详情
- **中间**：校园平面图，可点击交互
- **右侧**：路径查询面板（两点路径/多点路线）

## License

MIT License
