.PHONY: help build clean package docker-build docker-run test all

SHELL := /bin/bash

help:
	@echo "=== 校园导航系统构建工具 ==="
	@echo ""
	@echo "使用方法:"
	@echo "  make help              显示帮助信息"
	@echo "  make build             编译项目"
	@echo "  make clean             清理构建目录"
	@echo "  make package           打包项目"
	@echo "  make docker-build      构建 Docker 镜像"
	@echo "  make docker-run        运行 Docker 容器"
	@echo "  make docker-stop       停止 Docker 容器"
	@echo "  make docker-shell      进入 Docker 容器 Shell"
	@echo "  make all               完整构建流程 (推荐)"
	@echo ""
	@echo "环境变量:"
	@echo "  BUILD_TYPE=[Release|Debug]  构建类型 (默认: Release)"

build:
	@echo "=== 开始编译项目 ==="
	cd frontend-gui && mkdir -p build && cd build && \
	cmake .. -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) && \
	cmake --build . -- -j$$(nproc)
	@echo "=== 编译完成 ==="

clean:
	@echo "=== 清理构建目录 ==="
	rm -rf frontend-gui/build
	rm -rf dist
	@echo "=== 清理完成 ==="

package: build
	@echo "=== 开始打包项目 ==="
	mkdir -p dist
	cp frontend-gui/build/campus_nav_gui dist/
	@echo "=== 打包完成，输出目录: dist/ ==="

docker-build:
	@echo "=== 构建 Docker 镜像 ==="
	docker-compose build
	@echo "=== Docker 镜像构建完成 ==="

docker-run: docker-build
	@echo "=== 运行 Docker 容器 ==="
	@if [ "$$(uname)" = "Darwin" ] || [ "$$(uname)" = "Linux" ]; then \
		xhost +local:docker 2>/dev/null || true; \
	fi
	mkdir -p /tmp/runtime-user
	docker-compose up
	@echo "=== Docker 容器已停止 ==="

docker-stop:
	@echo "=== 停止 Docker 容器 ==="
	docker-compose down
	@echo "=== Docker 容器已停止 ==="

docker-shell:
	@echo "=== 进入 Docker 容器 Shell ==="
	docker-compose run --rm campus-nav-gui /bin/bash

all:
	@echo "=== 开始完整构建流程 ==="
	$(MAKE) build
	$(MAKE) package
	@echo "=== 完整构建流程完成 ==="
	@echo ""
	@echo "可执行文件位置: dist/campus_nav_gui"

BUILD_TYPE ?= Release
