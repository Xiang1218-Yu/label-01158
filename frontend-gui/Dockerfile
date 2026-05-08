ARG BUILD_PLATFORM=linux/amd64
ARG TARGET_PLATFORM=linux/amd64

FROM --platform=$BUILD_PLATFORM ubuntu:22.04 AS builder

LABEL maintainer="Campus Nav Team"
LABEL description="Campus Navigation GUI - Build Stage"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV LANG=C.UTF-8

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    qt6-base-dev \
    libgl1-mesa-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN mkdir -p build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/install && \
    make -j$(nproc) && \
    make install

FROM --platform=$TARGET_PLATFORM ubuntu:22.04

LABEL maintainer="Campus Nav Team"
LABEL description="Campus Navigation GUI"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV LANG=C.UTF-8
ENV QT_QPA_PLATFORM=offscreen

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
    libqt6widgets6 \
    libqt6gui6 \
    libqt6core6 \
    libgl1-mesa-glx \
    libxkbcommon0 \
    libxkbcommon-x11-0 \
    libfontconfig1 \
    libfreetype6 \
    libxcb1 \
    libxcb-xinerama0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-shm0 \
    libxcb-sync1 \
    libxcb-xfixes0 \
    libxcb-xkb1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /install/bin/campus_nav_gui .

RUN chmod +x campus_nav_gui

EXPOSE 8080

ENTRYPOINT ["./campus_nav_gui"]
