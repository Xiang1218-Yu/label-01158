# Windows 自动化构建脚本

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Join-Path $ScriptDir "frontend-gui"
$BuildDir = Join-Path $ProjectDir "build"
$OutputDir = Join-Path $ScriptDir "dist"

function Write-Info($msg) {
    Write-Host "[INFO] $msg" -ForegroundColor Cyan
}

function Write-Success($msg) {
    Write-Host "[SUCCESS] $msg" -ForegroundColor Green
}

function Write-Warning($msg) {
    Write-Host "[WARNING] $msg" -ForegroundColor Yellow
}

function Write-Error($msg) {
    Write-Host "[ERROR] $msg" -ForegroundColor Red
}

function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Check-Dependencies {
    Write-Info "检查依赖..."
    
    $needInstall = $false
    
    if (-not (Test-Command "cmake")) {
        Write-Warning "CMake 未安装"
        $needInstall = $true
    } else {
        $cmakeVersion = cmake --version | Select-Object -First 1
        Write-Success "CMake 已安装: $cmakeVersion"
    }
    
    $qtFound = $false
    if (Test-Command "qmake") {
        $qtVersion = qmake --version 2>$null
        if ($qtVersion -match "Qt version 6") {
            Write-Success "Qt6 已安装"
            $qtFound = $true
        }
    }
    
    if (-not $qtFound) {
        $qtPaths = @(
            "C:\Qt\6.*\msvc2019_64",
            "C:\Qt\6.*\msvc2022_64",
            "C:\Qt\6.*\mingw_64"
        )
        
        foreach ($pathPattern in $qtPaths) {
            $qtDirs = Get-ChildItem $pathPattern -Directory -ErrorAction SilentlyContinue
            if ($qtDirs) {
                foreach ($qtDir in $qtDirs) {
                    $qtBin = Join-Path $qtDir.FullName "bin"
                    if (Test-Path $qtBin) {
                        $env:PATH = "$qtBin;$env:PATH"
                        $env:CMAKE_PREFIX_PATH = $qtDir.FullName
                        Write-Success "Qt6 已找到: $qtDir"
                        $qtFound = $true
                        break
                    }
                }
            }
            if ($qtFound) { break }
        }
    }
    
    if (-not $qtFound) {
        Write-Warning "Qt6 未安装或未配置"
        Write-Warning "请从 https://www.qt.io/download 下载安装 Qt6"
        $needInstall = $true
    }
    
    return $needInstall
}

function Clean-Build {
    if (Test-Path $BuildDir) {
        Write-Info "清理旧的构建目录..."
        Remove-Item -Recurse -Force $BuildDir
        Write-Success "构建目录已清理"
    }
}

function Configure-Project {
    Write-Info "配置 CMake 项目..."
    
    if (-not (Test-Path $BuildDir)) {
        New-Item -ItemType Directory -Path $BuildDir | Out-Null
    }
    
    Set-Location $BuildDir
    
    cmake -DCMAKE_BUILD_TYPE=Release -G "Visual Studio 17 2022" -A x64 ..
    if ($LASTEXITCODE -ne 0) {
        cmake -DCMAKE_BUILD_TYPE=Release -G "Visual Studio 16 2019" -A x64 ..
    }
    
    if ($LASTEXITCODE -ne 0) {
        cmake -DCMAKE_BUILD_TYPE=Release ..
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "CMake 配置失败"
        exit 1
    }
    
    Write-Success "CMake 配置完成"
}

function Build-Project {
    Write-Info "开始编译项目..."
    
    Set-Location $BuildDir
    
    $cpuCount = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
    cmake --build . --config Release --parallel $cpuCount
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "项目编译失败"
        exit 1
    }
    
    Write-Success "项目编译完成"
}

function Package-Project {
    Write-Info "开始打包..."
    
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir | Out-Null
    }
    
    $releaseDir = Join-Path $BuildDir "Release"
    $executable = Join-Path $releaseDir "campus_nav_gui.exe"
    
    if (-not (Test-Path $executable)) {
        $executable = Join-Path $BuildDir "campus_nav_gui.exe"
    }
    
    if (-not (Test-Path $executable)) {
        Write-Error "可执行文件未找到"
        exit 1
    }
    
    $packageDir = Join-Path $OutputDir "campus_nav_gui-windows"
    if (Test-Path $packageDir) {
        Remove-Item -Recurse -Force $packageDir
    }
    New-Item -ItemType Directory -Path $packageDir | Out-Null
    
    Copy-Item $executable $packageDir
    
    $windeployqt = "windeployqt.exe"
    if (Test-Command $windeployqt) {
        Write-Info "使用 windeployqt 部署 Qt 依赖..."
        Set-Location $packageDir
        & $windeployqt "campus_nav_gui.exe" --no-translations --no-compiler-runtime
    } else {
        Write-Warning "windeployqt 未找到，未部署 Qt 依赖"
    }
    
    Write-Success "打包完成，输出目录: $packageDir"
}

function Show-Help {
    Write-Host ""
    Write-Host "Windows 自动化构建脚本" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "使用方法:"
    Write-Host "  .\build.ps1 [选项]"
    Write-Host ""
    Write-Host "选项:"
    Write-Host "  -Help          显示帮助信息"
    Write-Host "  -Clean         清理构建目录并重新构建"
    Write-Host "  -Build         仅编译项目"
    Write-Host "  -Package       仅打包项目"
    Write-Host "  -All           完整流程: 检查依赖 -> 编译 -> 打包 (默认)"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  .\build.ps1                    # 完整构建流程"
    Write-Host "  .\build.ps1 -Clean             # 清理并重新构建"
    Write-Host ""
}

function Main {
    param(
        [switch]$Help,
        [switch]$Clean,
        [switch]$Build,
        [switch]$Package,
        [switch]$All
    )
    
    if ($Help) {
        Show-Help
        return
    }
    
    $action = "all"
    if ($Build) { $action = "build" }
    elseif ($Package) { $action = "package" }
    elseif ($All) { $action = "all" }
    
    Write-Info "Windows 构建脚本启动"
    
    $needInstall = Check-Dependencies
    if ($needInstall) {
        $response = Read-Host "是否继续尝试构建? (Y/N)"
        if ($response -notmatch "^[Yy]$") {
            Write-Error "需要先安装依赖才能继续构建"
            exit 1
        }
    }
    
    if ($Clean) {
        Clean-Build
    }
    
    if ($action -eq "build" -or $action -eq "all") {
        Configure-Project
        Build-Project
    }
    
    if ($action -eq "package" -or $action -eq "all") {
        Package-Project
    }
    
    Write-Host ""
    Write-Success "构建流程完成！"
}

Main @args
