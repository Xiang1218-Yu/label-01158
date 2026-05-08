@echo off
setlocal EnableDelayedExpansion

set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..
set SOURCE_DIR=%PROJECT_ROOT%\frontend-gui
set BUILD_DIR=%SOURCE_DIR%\build
set PACKAGE_DIR=%PROJECT_ROOT%\dist
set APP_NAME=campus_nav_gui

if "%~1"=="" goto :help
if "%~1"=="install"   goto :install
if "%~1"=="configure" goto :configure
if "%~1"=="build"     goto :build
if "%~1"=="clean"     goto :clean
if "%~1"=="package"   goto :package
if "%~1"=="run"       goto :run
if "%~1"=="help"      goto :help
if "%~1"=="-h"        goto :help
if "%~1"=="--help"    goto :help

echo [ERROR] 未知命令: %~1
echo.
goto :help

:install
echo [INFO] 检测 Windows 依赖...

where cmake >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [INFO] 未找到 CMake，正在使用 winget 安装...
    winget install Kitware.CMake
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] winget 安装 CMake 失败，请手动安装: https://cmake.org/download/
        exit /b 1
    )
)

where cmake >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] CMake 仍未找到，请重启终端后再试
    exit /b 1
)

set QT_FOUND=0

if defined CMAKE_PREFIX_PATH (
    echo !CMAKE_PREFIX_PATH! | findstr /i "Qt" >nul && set QT_FOUND=1
)

if "!QT_FOUND!"=="0" (
    if exist "C:\Qt\6" (
        for /d %%d in (C:\Qt\6\*) do (
            if exist "%%d\msvc*\lib\cmake\Qt6" (
                set QT_DIR=%%d\msvc2022_64
                set QT_FOUND=1
                goto :qt_found
            )
        )
    )
    if exist "C:\Qt\6" (
        for /d %%d in (C:\Qt\6\*) do (
            if exist "%%d\mingw*\lib\cmake\Qt6" (
                set QT_DIR=%%d\mingw1310_64
                set QT_FOUND=1
                goto :qt_found
            )
        )
    )
)

:qt_found
if "!QT_FOUND!"=="0" (
    echo [WARN] 未找到 Qt6 安装
    echo [INFO] 尝试使用 winget 安装 Qt6...
    winget install Qt.Qt6
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Qt6 自动安装失败
        echo [INFO] 请从以下地址手动安装 Qt6:
        echo        https://www.qt.io/download-open-source
        echo [INFO] 安装后设置环境变量:
        echo        set CMAKE_PREFIX_PATH=C:\Qt\6.x.x\msvc2022_64
        exit /b 1
    )
)

echo [OK] Windows 依赖安装完成
goto :eof

:configure
echo [INFO] 配置 CMake...

if not exist "%SOURCE_DIR%" (
    echo [ERROR] 源码目录不存在: %SOURCE_DIR%
    exit /b 1
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

set CMAKE_ARGS=-B "%BUILD_DIR%" -S "%SOURCE_DIR%"

if defined CMAKE_PREFIX_PATH (
    set CMAKE_ARGS=!CMAKE_ARGS! -DCMAKE_PREFIX_PATH=!CMAKE_PREFIX_PATH!
) else if defined QT_DIR (
    set CMAKE_ARGS=!CMAKE_ARGS! -DCMAKE_PREFIX_PATH=!QT_DIR!
)

cmake !CMAKE_ARGS!
if %ERRORLEVEL% neq 0 (
    echo [ERROR] CMake 配置失败
    exit /b 1
)

echo [OK] CMake 配置完成
goto :eof

:build
echo [INFO] 编译项目...

if not exist "%BUILD_DIR%\CMakeCache.txt" (
    call :configure
    if %ERRORLEVEL% neq 0 exit /b 1
)

cmake --build "%BUILD_DIR%" --config Release --parallel
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 编译失败
    exit /b 1
)

echo [OK] 编译完成: %BUILD_DIR%\Release\%APP_NAME%.exe
goto :eof

:clean
echo [INFO] 清理构建目录...
if exist "%BUILD_DIR%" (
    rmdir /s /q "%BUILD_DIR%"
)
echo [OK] 清理完成
goto :eof

:package
echo [INFO] 打包应用...

call :build
if %ERRORLEVEL% neq 0 exit /b 1

if exist "%PACKAGE_DIR%" rmdir /s /q "%PACKAGE_DIR%"
mkdir "%PACKAGE_DIR%"

set PKG_DIR=%PACKAGE_DIR%\%APP_NAME%
mkdir "%PKG_DIR%\bin"

set EXE_PATH=%BUILD_DIR%\Release\%APP_NAME%.exe
if not exist "!EXE_PATH!" (
    set EXE_PATH=%BUILD_DIR%\%APP_NAME%.exe
)

copy "!EXE_PATH!" "%PKG_DIR%\bin\" >nul

where windeployqt >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [INFO] 部署 Qt 依赖...
    windeployqt --release --no-translations --dir "%PKG_DIR%\bin" "!EXE_PATH!"
) else (
    echo [WARN] 未找到 windeployqt，跳过 Qt 依赖部署
    echo [WARN] 在其他 Windows 上运行可能需要安装 Qt6
)

set TIMESTAMP=%date:~0,4%%date:~5,2%%date:~8,2%
set ZIP_NAME=%APP_NAME%-windows-!TIMESTAMP!.zip

where 7z >nul 2>&1
if %ERRORLEVEL% equ 0 (
    7z a -tzip "%PACKAGE_DIR%\!ZIP_NAME!" "%PKG_DIR%\*" >nul
    echo [OK] Windows 打包: %PACKAGE_DIR%\!ZIP_NAME!
) else (
    powershell -Command "Compress-Archive -Path '%PKG_DIR%\*' -DestinationPath '%PACKAGE_DIR%\!ZIP_NAME!' -Force" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo [OK] Windows 打包: %PACKAGE_DIR%\!ZIP_NAME!
    ) else (
        echo [OK] 打包目录已生成: %PKG_DIR%
        echo [INFO] 如需 zip，请安装 7-Zip 或确保 PowerShell 可用
    )
)

goto :eof

:run
call :build
if %ERRORLEVEL% neq 0 exit /b 1

echo [INFO] 启动程序...

set EXE_PATH=%BUILD_DIR%\Release\%APP_NAME%.exe
if not exist "!EXE_PATH!" (
    set EXE_PATH=%BUILD_DIR%\%APP_NAME%.exe
)

"!EXE_PATH!"
goto :eof

:help
echo %APP_NAME% 自动化构建脚本 (Windows)
echo.
echo 用法: %~nx0 ^<命令^>
echo.
echo 命令:
echo   install    检测并安装依赖 (cmake, qt6 等^)
echo   configure  配置 CMake 构建
echo   build      编译项目 (自动配置，如未配置^)
echo   clean      清理构建目录
echo   package    编译并打包为可分发 zip
echo   run        编译并运行
echo   help       显示此帮助信息
echo.
echo 示例:
echo   scripts\build.bat install     首次使用：安装所有依赖
echo   scripts\build.bat build       编译项目
echo   scripts\build.bat package     编译并打包
echo   scripts\build.bat run         编译并运行
echo.
echo 环境变量:
echo   CMAKE_PREFIX_PATH  Qt6 安装路径 (如 C:\Qt\6.5.0\msvc2022_64^)
goto :eof
