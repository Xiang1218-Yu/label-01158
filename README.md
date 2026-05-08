# 安徽理工大学校园导航系统

基于最短路径算法的校园导游程序，使用 Qt6 图形界面，为来访客人提供景点信息查询和路径规划服务。

## How to Run

### 自动化构建（推荐）

项目提供跨平台自动化构建脚本，一键完成依赖安装、编译和打包。

**macOS / Linux:**
```bash
# 首次使用：安装依赖
./scripts/build.sh install

# 编译项目
./scripts/build.sh build

# 编译并运行
./scripts/build.sh run

# 编译并打包
./scripts/build.sh package
```

**Windows:**
```cmd
REM 首次使用：安装依赖
scripts\build.bat install

REM 编译项目
scripts\build.bat build

REM 编译并运行
scripts\build.bat run

REM 编译并打包
scripts\build.bat package
```

**可用命令：**

| 命令 | 说明 |
|------|------|
| `install` | 自动检测平台并安装依赖 |
| `configure` | 配置 CMake 构建 |
| `build` | 编译项目 |
| `clean` | 清理构建目录 |
| `package` | 编译并打包为可分发格式 |
| `run` | 编译并运行 |
| `docker` | 使用 Docker 构建 (仅 macOS/Linux) |

**打包产物：**
- macOS → `dist/campus_nav_gui.app` (含 Qt 框架依赖)
- Linux → `dist/campus_nav_gui-linux-YYYYMMDD.tar.gz`
- Windows → `dist/campus_nav_gui-windows-YYYYMMDD.zip` (含 Qt DLL)

---

### 手动构建

<details>
<summary>点击展开手动构建步骤</summary>

#### 步骤1: 安装依赖

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
- 设置环境变量: `set CMAKE_PREFIX_PATH=C:\Qt\6.x.x\msvc2022_64`

#### 步骤2: 编译

```bash
cd frontend-gui
mkdir -p build && cd build
cmake ..
make
```

#### 步骤3: 运行

```bash
./campus_nav_gui
```

</details>

### VS Code 调试运行

1. 用 VS Code 打开项目根目录
2. 按 `Cmd+Shift+B` (macOS) 或 `Ctrl+Shift+B` (Windows/Linux) 编译
3. 按 `F5` 启动调试

### Docker 运行（Linux with X11）

```bash
# 允许 X11 连接
xhost +local:docker

# 启动容器
docker-compose up --build

# 停止
docker-compose down
```

### CI/CD 自动构建与发布

项目配置了 GitHub Actions，实现全自动的持续集成和发布流程。

**持续集成 (CI)：**

每次推送到 `main`/`master`/`develop` 分支或提交 PR 时，自动在三个平台上编译：

| 平台 | Runner | 依赖安装方式 |
|------|--------|------------|
| Linux | ubuntu-22.04 | apt |
| macOS | macos-14 (ARM) | Homebrew |
| Windows | windows-2022 | install-qt-action |

编译产物会作为 Artifact 保留 7 天，可供下载验证。

**自动发布 (Release)：**

推送版本标签时自动打包发布到 GitHub Releases：

```bash
# 创建版本标签并推送，触发自动发布
git tag v1.0.0
git push origin v1.0.0
```

自动生成的发布产物：

| 平台 | 产物格式 | 说明 |
|------|---------|------|
| Linux | `campus_nav_gui-linux-x86_64.tar.gz` | 含可执行文件 |
| macOS | `campus_nav_gui-macos-arm64.dmg` | 含 Qt 框架的 DMG 镜像 |
| Windows | `campus_nav_gui-windows-x86_64.zip` | 含 Qt DLL 的完整包 |

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
| CI/CD | GitHub Actions | 自动编译和发布 |
| 容器化 | Docker | 可选的容器化部署 |

### 核心算法

- **Dijkstra 算法**：求解两点间最短路径，时间复杂度 O((V+E)logV)
- **贪心算法**：多景点路径规划，每次选择最近的未访问景点

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
├── scripts/                   # 自动化构建脚本
│   ├── build.sh               # macOS/Linux 构建脚本
│   └── build.bat              # Windows 构建脚本
├── .github/                   # CI/CD 配置
│   └── workflows/
│       ├── ci.yml             # 持续集成工作流
│       └── release.yml        # 自动发布工作流
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
