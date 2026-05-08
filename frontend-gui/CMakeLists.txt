cmake_minimum_required(VERSION 3.16)
project(campus_nav_gui)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 COMPONENTS Widgets REQUIRED)

add_executable(campus_nav_gui
    src/main.cpp
    src/mainwindow.cpp
    src/mapwidget.cpp
    src/graph.cpp
    src/campus_data.cpp
    include/mainwindow.h
    include/mapwidget.h
    resources/resources.qrc
)

target_include_directories(campus_nav_gui PRIVATE
    ${CMAKE_SOURCE_DIR}/include
)

target_link_libraries(campus_nav_gui PRIVATE Qt6::Widgets)
